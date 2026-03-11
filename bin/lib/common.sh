fail() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_docker_compose() {
	docker compose version >/dev/null 2>&1 || fail "docker compose is required"
}

is_help_flag() {
	case "${1:-}" in
	-h | --help)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

list_existing_shell_files() {
	local shell_file=""

	while IFS= read -r shell_file; do
		[[ -f "${ROOT_DIR}/${shell_file}" ]] || continue
		printf '%s\n' "$shell_file"
	done < <(git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard '*.sh')
}

require_host_name() {
	[[ -n "${HOST_NAME:-}" ]] || fail "host name is required"
}

set_host_paths() {
	HOST_DIR="${ROOT_DIR}/stacks/${HOST_NAME}"
	ENV_FILE="${HOST_DIR}/.env"

	[[ -d "$HOST_DIR" ]] || fail "unknown host '${HOST_NAME}' (missing ${HOST_DIR})"
}

require_local_env_file() {
	[[ -f "$ENV_FILE" ]] || fail "missing ${ENV_FILE}; copy ${HOST_DIR}/.env.example to ${ENV_FILE} first"
}

load_host_env() {
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
}

load_enabled_stacks() {
	local compose_file=""
	local stack_name=""

	ENABLED_STACKS=()

	while IFS= read -r compose_file; do
		stack_name="$(basename -- "$(dirname -- "$compose_file")")"
		ENABLED_STACKS+=("$stack_name")
	done < <(find "$HOST_DIR" -mindepth 2 -maxdepth 2 -type f -name 'compose.yaml' | sort)
}

stack_dir() {
	printf '%s/%s' "$HOST_DIR" "$1"
}

run_compose() {
	local stack_name="$1"
	shift
	local directory=""

	directory="$(stack_dir "$stack_name")"
	[[ -d "$directory" ]] || fail "missing stack directory: ${directory}"

	(
		cd -- "$directory" || exit 1
		docker compose --project-name "${HOST_NAME}_${stack_name}" "$@"
	)
}

is_enabled_stack() {
	local candidate="$1"
	local stack_name=""

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "$candidate" ]] && return 0
	done

	return 1
}

stop_enabled_stacks() {
	local extra_args=("$@")
	local stack_name=""
	local index=0

	for ((index = ${#ENABLED_STACKS[@]} - 1; index >= 0; index--)); do
		stack_name="${ENABLED_STACKS[index]}"
		[[ "$stack_name" == "reverse_proxy" ]] && continue
		printf 'stopping %s\n' "$stack_name"
		run_compose "$stack_name" down "${extra_args[@]}"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] || continue
		printf 'stopping %s\n' "$stack_name"
		run_compose "$stack_name" down "${extra_args[@]}"
	done
}

remove_edge_network_if_unused() {
	local attached_count=""

	[[ -n "${EDGE_NETWORK:-}" ]] || fail "EDGE_NETWORK must be set in ${ENV_FILE}"

	if ! docker network inspect "$EDGE_NETWORK" >/dev/null 2>&1; then
		printf 'network not present: %s\n' "$EDGE_NETWORK"
		return
	fi

	attached_count="$(docker network inspect "$EDGE_NETWORK" --format '{{ len .Containers }}')"
	if [[ "$attached_count" != "0" ]]; then
		printf 'keeping network %s (%s attached containers)\n' "$EDGE_NETWORK" "$attached_count"
		return
	fi

	docker network rm "$EDGE_NETWORK" >/dev/null
	printf 'removed external network: %s\n' "$EDGE_NETWORK"
}

target_path_for_example() {
	local example_file="$1"

	case "$example_file" in
	*.example.yaml)
		printf '%s.yaml' "${example_file%.example.yaml}"
		;;
	*.example)
		printf '%s' "${example_file%.example}"
		;;
	*)
		fail "unsupported example file: ${example_file}"
		;;
	esac
}

target_path_for_template() {
	local template_file="$1"

	case "$template_file" in
	*.template.yaml)
		printf '%s.yaml' "${template_file%.template.yaml}"
		;;
	*.template)
		printf '%s' "${template_file%.template}"
		;;
	*)
		fail "unsupported template file: ${template_file}"
		;;
	esac
}

ensure_template_context() {
	local template_file="$1"

	if grep -q '\${HEADPLANE_COOKIE_SECRET}' "$template_file"; then
		if [[ -z "${HEADPLANE_COOKIE_SECRET:-}" ]]; then
			HEADPLANE_COOKIE_SECRET="$(openssl rand -hex 16)"
			export HEADPLANE_COOKIE_SECRET
			printf 'generated HEADPLANE_COOKIE_SECRET for %s\n' "${template_file#"${ROOT_DIR}/"}"
		fi
	fi
}

require_template_variables() {
	local template_file="$1"
	local variable_name=""

	while IFS= read -r variable_name; do
		[[ -n "$variable_name" ]] || continue
		[[ -n "${!variable_name:-}" ]] || fail "missing ${variable_name} for ${template_file#"${ROOT_DIR}/"}"
	done < <((grep -o '\${[A-Z0-9_][A-Z0-9_]*}' "$template_file" || true) | tr -d '$}{' | sort -u)
}

render_template_to_file() {
	local template_file="$1"
	local target_file="$2"

	ensure_template_context "$template_file"
	require_template_variables "$template_file"
	envsubst <"$template_file" >"$target_file"
}

remove_stack_runtime_files() {
	local stack_name="$1"
	local stack_directory=""
	local template_file=""
	local example_file=""
	local target_file=""

	stack_directory="$(stack_dir "$stack_name")"

	if [[ -d "$stack_directory/data" ]]; then
		find "$stack_directory/data" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} +
		printf 'cleared %s\n' "${stack_directory#"${ROOT_DIR}/"}/data"
	fi

	while IFS= read -r template_file; do
		target_file="$(target_path_for_template "$template_file")"
		if [[ -f "$target_file" ]]; then
			rm -f "$target_file"
			printf 'removed %s\n' "${target_file#"${ROOT_DIR}/"}"
		fi
	done < <(find "$stack_directory" -type f \( -name '*.template' -o -name '*.template.yaml' \) | sort)

	while IFS= read -r example_file; do
		target_file="$(target_path_for_example "$example_file")"
		if [[ -f "$target_file" ]]; then
			rm -f "$target_file"
			printf 'removed %s\n' "${target_file#"${ROOT_DIR}/"}"
		fi
	done < <(find "$stack_directory" -type f \( -name '*.example' -o -name '*.example.yaml' \) | sort)
}
