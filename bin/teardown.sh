#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
REMOVE_MODE=false
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/teardown.sh [--remove] <host>

Stop enabled stacks, remove compose resources, and clean up the shared edge
network when it is no longer in use.

Options:
  --remove   Also remove stack images and clear rendered config/data files.
  -h, --help Show this help.
EOF
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--remove)
			REMOVE_MODE=true
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			if [[ -z "$HOST_NAME" ]]; then
				HOST_NAME="$1"
				shift
				continue
			fi

			fail "unexpected argument: $1"
			;;
		esac
	done
}

main() {
	HOST_NAME=""
	parse_args "$@"

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
	else
		if [[ "$REMOVE_MODE" == true ]]; then
			stop_enabled_stacks --remove-orphans -v --rmi all
		else
			stop_enabled_stacks --remove-orphans -v
		fi
	fi

	if [[ "$REMOVE_MODE" == true ]]; then
		local stack_name=""
		for stack_name in "${ENABLED_STACKS[@]}"; do
			remove_stack_runtime_files "$stack_name"
		done
		printf 'stack images and rendered runtime files were removed\n'
	else
		printf 'bind-mounted data and rendered config files were left in place\n'
	fi

	remove_edge_network_if_unused
}

main "$@"
