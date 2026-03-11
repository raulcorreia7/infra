#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
STACKS_FILE=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/up.sh <host>

Start enabled stacks for one host.
EOF
}

fail() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_docker_compose() {
	docker compose version >/dev/null 2>&1 || fail "docker compose is required"
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
	local directory

	directory="$(stack_dir "$stack_name")"
	[[ -d "$directory" ]] || fail "missing stack directory: ${directory}"

	(
		cd -- "$directory"
		docker compose --project-name "${HOST_NAME}_${stack_name}" "$@"
	)
}

run_post_hook() {
	local stack_name="$1"
	local hook_path="$(stack_dir "$stack_name")/post.sh"

	if [[ ! -x "$hook_path" ]]; then
		return 0
	fi

	printf 'running %s post hook\n' "$stack_name"
	"$hook_path"
}

start_stack() {
	local stack_name="$1"
	printf 'starting %s\n' "$stack_name"
	run_compose "$stack_name" up -d
	run_post_hook "$stack_name"
}

main() {
	require_host_name
	set_host_paths
	require_command docker
	require_docker_compose
	load_host_env
	load_enabled_stacks

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	local stack_name=""

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] || continue
		start_stack "$stack_name"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] && continue
		start_stack "$stack_name"
	done
}

main "$@"
