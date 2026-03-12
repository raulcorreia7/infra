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
Usage: bin/down.sh <host>

Stop enabled stacks for one host.

Options:
  -h, --help Show this help.
EOF
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

	print_section "Down"
	log_step "stopping ${HOST_NAME}"

	# shellcheck disable=SC2119
	stop_enabled_stacks
	log_ok "host is down: ${HOST_NAME}"
}

main "$@"
