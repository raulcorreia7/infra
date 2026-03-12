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
Usage: bin/refresh-config.sh <host>

Remove generated template outputs for a host, then rerun setup so tracked
template changes take effect without touching runtime data.

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

	print_section "Refresh Config"
	log_step "removing rendered template files for ${HOST_NAME}"

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		remove_stack_rendered_files "$stack_name"
	done

	log_step "rerunning setup for ${HOST_NAME}"
	"${ROOT_DIR}/bin/setup.sh" "$HOST_NAME"
	log_ok "refreshed rendered config for ${HOST_NAME}"
}

main "$@"
