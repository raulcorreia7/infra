#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/up.sh <host>

Start enabled stacks for one host.

Options:
  -h, --help Show this help.
EOF
}

run_stack_up_script() {
	local stack_name="$1"
	local script_path=""

	script_path="$(stack_dir "$stack_name")/stack-up.sh"

	[[ -x "$script_path" ]] || return 0

	printf 'running %s stack-up script\n' "$stack_name"
	"$script_path"
}

start_stack() {
	local stack_name="$1"
	printf 'starting %s\n' "$stack_name"
	run_compose "$stack_name" up -d
	run_stack_up_script "$stack_name"
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
