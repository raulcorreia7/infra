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

require_host_name() {
	[[ -n "${HOST_NAME:-}" ]] || fail "host name is required"
}

set_host_paths() {
	HOST_DIR="${ROOT_DIR}/hosts/${HOST_NAME}"
	ENV_FILE="${HOST_DIR}/.env"
	STACKS_FILE="${HOST_DIR}/stacks.txt"

	[[ -d "$HOST_DIR" ]] || fail "unknown host '${HOST_NAME}' (missing ${HOST_DIR})"
	[[ -f "$STACKS_FILE" ]] || fail "missing stacks file: ${STACKS_FILE}"
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
	local raw_line=""
	local stack_name=""

	ENABLED_STACKS=()

	while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
		stack_name="${raw_line%%#*}"
		stack_name="$(trim "$stack_name")"

		[[ -n "$stack_name" ]] || continue
		ENABLED_STACKS+=("$stack_name")
	done <"$STACKS_FILE"
}

stack_dir() {
	printf '%s/stacks/%s' "$ROOT_DIR" "$1"
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
