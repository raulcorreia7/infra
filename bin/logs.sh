#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-}"
STACK_FILTER="${2:-}"
HOST_DIR=""
ENV_FILE=""
declare -a ENABLED_STACKS=()
declare -a LOG_PIDS=()

usage() {
	cat <<'EOF'
Usage: bin/logs.sh <host> [stack]

Follow logs for one enabled stack or all enabled stacks.

Options:
  -h, --help Show this help.
EOF
}

cleanup_logs() {
	local pid=""

	for pid in "${LOG_PIDS[@]:-}"; do
		[[ -n "$pid" ]] || continue
		kill "$pid" >/dev/null 2>&1 || true
	done
}

follow_stack_logs() {
	local stack_name="$1"
	printf -- '\n== %s ==\n' "$stack_name"
	run_compose "$stack_name" logs -f --tail 100 &
	LOG_PIDS+=("$!")
}

main() {
	if is_help_flag "$HOST_NAME"; then
		usage
		return
	fi

	if [[ -z "$HOST_NAME" ]]; then
		usage >&2
		exit 1
	fi

	set_host_paths
	require_local_env_file
	load_host_env
	load_enabled_stacks

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		log_step "no enabled stacks for ${HOST_NAME}"
		return
	fi

	require_command docker
	require_docker_compose

	if [[ -n "$STACK_FILTER" ]]; then
		is_enabled_stack "$STACK_FILTER" || fail "stack '${STACK_FILTER}' is not enabled for host ${HOST_NAME}"
		print_section "Logs"
		log_step "following ${STACK_FILTER} on ${HOST_NAME}"
		run_compose "$STACK_FILTER" logs -f --tail 100
		return
	fi

	trap cleanup_logs EXIT INT TERM
	print_section "Logs"
	log_step "following all stacks on ${HOST_NAME}"

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
