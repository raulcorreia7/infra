#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
STACKS_FILE=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/down.sh <host>

Stop enabled stacks for one host.
EOF
}

stop_stack() {
	local stack_name="$1"
	printf 'stopping %s\n' "$stack_name"
	run_compose "$stack_name" down
}

main() {
	if [[ -z "$HOST_NAME" ]]; then
		usage >&2
		exit 1
	fi

	require_command docker
	require_docker_compose
	set_host_paths
	require_local_env_file
	load_host_env
	load_enabled_stacks

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	local stack_name=""
	local index=0

	for ((index = ${#ENABLED_STACKS[@]} - 1; index >= 0; index--)); do
		stack_name="${ENABLED_STACKS[index]}"
		[[ "$stack_name" == "reverse_proxy" ]] && continue
		stop_stack "$stack_name"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "reverse_proxy" ]] || continue
		stop_stack "$stack_name"
	done
}

main "$@"
