#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOST_NAME="${1:-}"
STACK_FILTER="${2:-}"
HOST_DIR=""
ENV_FILE=""
STACKS_FILE=""
declare -a ENABLED_STACKS=()
declare -a LOG_PIDS=()

usage() {
	cat <<'EOF'
Usage: bin/logs.sh <host> [stack]

Follow logs for one enabled stack or all enabled stacks.
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

is_enabled_stack() {
	local candidate="$1"
	local stack_name=""

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "$candidate" ]] && return 0
	done

	return 1
}

cleanup_logs() {
	local pid=""

	for pid in "${LOG_PIDS[@]:-}"; do
		[[ -n "$pid" ]] || continue
		if kill -0 "$pid" >/dev/null 2>&1; then
			kill "$pid" >/dev/null 2>&1 || true
		fi
	done
}

follow_stack_logs() {
	local stack_name="$1"
	printf '===== %s =====\n' "$stack_name"
	run_compose "$stack_name" logs -f --tail 100 &
	LOG_PIDS+=("$!")
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

	if [[ -n "$STACK_FILTER" ]]; then
		is_enabled_stack "$STACK_FILTER" || fail "stack '${STACK_FILTER}' is not enabled for host ${HOST_NAME}"
		run_compose "$STACK_FILTER" logs -f --tail 100
		return
	fi

	trap cleanup_logs EXIT INT TERM

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] || continue
		follow_stack_logs "$stack_name"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] && continue
		follow_stack_logs "$stack_name"
	done

	wait
}

main "$@"
