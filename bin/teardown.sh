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
Usage: bin/teardown.sh <host>

Stop enabled stacks, remove compose resources, and clean up the shared edge
network when it is no longer in use.
EOF
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
	else
		stop_enabled_stacks --remove-orphans -v
	fi

	remove_edge_network_if_unused
	printf 'bind-mounted data and rendered config files were left in place\n'
}

main "$@"
