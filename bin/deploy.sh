#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

SSH_PORT="22"
SSH_TARGET=""
HOST_NAME=""
REMOTE_PATH=""

usage() {
	cat <<'EOF'
Usage: bin/deploy.sh [options] [user@]host <host> [remote-path]

Sync the repo to a remote machine, then run the normal bring-up workflow there.

Options:
  -p, --port PORT   SSH port (default: 22).
  -h, --help        Show this help.

Examples:
  bin/deploy.sh root@cerberus cerberus
  bin/deploy.sh -p 2222 root@example.com cerberus /opt/infra
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

			if [[ -z "$HOST_NAME" ]]; then
				HOST_NAME="$1"
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
	[[ -n "$HOST_NAME" ]] || {
		usage >&2
		exit 1
	}
	if [[ -z "$REMOTE_PATH" ]]; then
		REMOTE_PATH='infra'
	fi

	"${ROOT_DIR}/bin/sync.sh" -p "$SSH_PORT" "$SSH_TARGET" "$REMOTE_PATH"

	ssh -p "$SSH_PORT" "$SSH_TARGET" \
		"cd \"$REMOTE_PATH\" && ./bin/doctor.sh \"$HOST_NAME\" && ./bin/refresh-config.sh \"$HOST_NAME\" && ./bin/validate-config.sh \"$HOST_NAME\" && ./bin/up.sh \"$HOST_NAME\" && ./bin/health.sh \"$HOST_NAME\""
}

main "$@"
