#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
STACKS_FILE=""
EDGE_NETWORK=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/setup.sh <host>

Prepare one host for running enabled Docker Compose stacks.
EOF
}

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

require_host_name() {
	[[ -n "$HOST_NAME" ]] || {
		usage >&2
		exit 1
	}
}

set_host_paths() {
	HOST_DIR="${ROOT_DIR}/hosts/${HOST_NAME}"
	ENV_FILE="${HOST_DIR}/.env"
	STACKS_FILE="${HOST_DIR}/stacks.txt"

	[[ -d "$HOST_DIR" ]] || fail "unknown host '${HOST_NAME}' (missing ${HOST_DIR})"
	[[ -f "$STACKS_FILE" ]] || fail "missing stacks file: ${STACKS_FILE}"
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_docker_compose() {
	docker compose version >/dev/null 2>&1 || fail "docker compose is required"
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

load_host_env() {
	[[ -f "$ENV_FILE" ]] || fail "missing ${ENV_FILE}; copy ${HOST_DIR}/.env.example to ${ENV_FILE} first"

	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a

	[[ -n "${EDGE_NETWORK:-}" ]] || fail "EDGE_NETWORK must be set in ${ENV_FILE}"
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

ensure_edge_network() {
	if docker network inspect "$EDGE_NETWORK" >/dev/null 2>&1; then
		printf 'network already present: %s\n' "$EDGE_NETWORK"
		return
	fi

	docker network create "$EDGE_NETWORK" >/dev/null
	printf 'created external network: %s\n' "$EDGE_NETWORK"
}

copy_example_file() {
	local example_file="$1"
	local target_file=""
	local generated_secret=""

	target_file="$(target_path_for_example "$example_file")"

	[[ -e "$target_file" ]] && return

	cp "$example_file" "$target_file"

	if grep -q 'REPLACE_WITH_32_CHAR_SECRET' "$target_file"; then
		generated_secret="$(openssl rand -hex 16)"
		sed -i "s/REPLACE_WITH_32_CHAR_SECRET/${generated_secret}/g" "$target_file"
	fi

	printf 'created %s\n' "${target_file#"${ROOT_DIR}/"}"
}

ensure_stack_directories() {
	local stack_name="$1"
	local stack_dir="$2"

	case "$stack_name" in
	headscale_vpn)
		mkdir -p "$stack_dir/data/headscale" "$stack_dir/data/headplane"
		printf 'ensured %s\n' "${stack_dir#"${ROOT_DIR}/"}/data/headscale"
		printf 'ensured %s\n' "${stack_dir#"${ROOT_DIR}/"}/data/headplane"
		;;
	reverse_proxy)
		mkdir -p "$stack_dir/data"
		printf 'ensured %s\n' "${stack_dir#"${ROOT_DIR}/"}/data"
		;;
	*)
		mkdir -p "$stack_dir/data"
		printf 'ensured %s\n' "${stack_dir#"${ROOT_DIR}/"}/data"
		;;
	esac
}

prepare_stack() {
	local stack_name="$1"
	local stack_dir="${ROOT_DIR}/stacks/${stack_name}"
	local example_file=""

	[[ -d "$stack_dir" ]] || fail "missing stack directory: ${stack_dir}"

	ensure_stack_directories "$stack_name" "$stack_dir"

	while IFS= read -r example_file; do
		copy_example_file "$example_file"
	done < <(find "$stack_dir" -type f \( -name '*.example' -o -name '*.example.yaml' \) | sort)
}

main() {
	require_host_name
	set_host_paths
	require_command docker
	require_command openssl
	require_docker_compose
	load_host_env
	load_enabled_stacks
	ensure_edge_network

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		prepare_stack "$stack_name"
	done
}

main "$@"
