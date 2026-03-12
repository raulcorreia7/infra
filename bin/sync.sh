#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

SSH_PORT="22"
SSH_TARGET=""
REMOTE_PATH=""

usage() {
	cat <<'EOF'
Usage: bin/sync.sh [options] [user@]host [remote-path]

Sync the tracked repo contents to a remote host over SSH using rsync.
Remote local env files, credentials, rendered config, and runtime data are left
in place.

Options:
  -p, --port PORT   SSH port (default: 22).
  -h, --help        Show this help.

Examples:
  bin/sync.sh root@cerberus
  bin/sync.sh -p 2222 root@example.com /opt/infra
EOF
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		-p | --port)
			[[ "$#" -ge 2 ]] || fail "missing value for $1"
			SSH_PORT="$2"
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		-*)
			fail "unknown option: $1"
			;;
		*)
			if [[ -z "$SSH_TARGET" ]]; then
				SSH_TARGET="$1"
				shift
				continue
			fi

			if [[ -z "$REMOTE_PATH" ]]; then
				REMOTE_PATH="$1"
				shift
				continue
			fi

			fail "unexpected argument: $1"
			;;
		esac
	done
}

main() {
	parse_args "$@"
	[[ -n "$SSH_TARGET" ]] || {
		usage >&2
		exit 1
	}
	if [[ -z "$REMOTE_PATH" ]]; then
		REMOTE_PATH='infra'
	fi

	require_command rsync
	require_command ssh

	print_section "Sync"
	log_step "syncing repo to ${SSH_TARGET}:${REMOTE_PATH}"

	rsync -az --delete \
		-e "ssh -p ${SSH_PORT}" \
		--exclude '.git/' \
		--exclude 'stacks/*/.env' \
		--exclude 'stacks/*/*/.env' \
		--exclude 'stacks/*/*/data/' \
		--exclude 'stacks/*/*/config/Caddyfile' \
		--exclude 'stacks/*/*/config/policy.yaml' \
		--exclude 'stacks/*/*/config/**/config.yaml' \
		--exclude 'dns/.env' \
		--exclude 'dns/creds.json' \
		--exclude 'tools/dnscontrol/dnscontrol' \
		"${ROOT_DIR}/" "${SSH_TARGET}:${REMOTE_PATH}/"

	log_ok "synced repo to ${SSH_TARGET}:${REMOTE_PATH}"
}

main "$@"
