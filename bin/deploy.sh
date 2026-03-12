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
REMOTE_MODE=false

usage() {
	cat <<'EOF'
Usage: bin/deploy.sh [options] <host>

Run the normal deploy workflow for one host.

By default this deploys the current repo copy on the current machine.
Use `--remote` to sync to another machine and run the same deploy workflow there.

Options:
  -r, --remote HOST  Sync to and deploy on a remote SSH host.
      --path PATH    Remote repo path when using --remote (default: infra).
  -p, --port PORT   SSH port (default: 22).
  -h, --help        Show this help.

Examples:
  bin/deploy.sh cerberus
  bin/deploy.sh --remote root@cerberus.raulcorreia.dev cerberus
  bin/deploy.sh --remote root@example.com --path /opt/infra cerberus
EOF
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		-r | --remote)
			[[ "$#" -ge 2 ]] || fail "missing value for $1"
			REMOTE_MODE=true
			SSH_TARGET="$2"
			shift 2
			;;
		--path)
			[[ "$#" -ge 2 ]] || fail "missing value for $1"
			REMOTE_PATH="$2"
			shift 2
			;;
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

run_local_workflow() {
	print_section "Deploy"
	log_step "deploying ${HOST_NAME} on the current machine"
	"${ROOT_DIR}/bin/setup.sh" --refresh "$HOST_NAME"
	"${ROOT_DIR}/bin/validate-config.sh" "$HOST_NAME"
	"${ROOT_DIR}/bin/up.sh" "$HOST_NAME"
	"${ROOT_DIR}/bin/health.sh" "$HOST_NAME"
	log_ok "deploy completed for ${HOST_NAME}"
}

run_remote_workflow() {
	[[ -n "$SSH_TARGET" ]] || fail '--remote requires an SSH target'
	if [[ -z "$REMOTE_PATH" ]]; then
		REMOTE_PATH='infra'
	fi

	print_section "Deploy"
	log_step "deploying ${HOST_NAME} to ${SSH_TARGET}:${REMOTE_PATH}"
	"${ROOT_DIR}/bin/helpers/sync.sh" -p "$SSH_PORT" --path "$REMOTE_PATH" "$SSH_TARGET"
	log_step "running remote deploy for ${HOST_NAME}"
	ssh -p "$SSH_PORT" "$SSH_TARGET" "cd \"$REMOTE_PATH\" && ./bin/deploy.sh \"$HOST_NAME\""
	log_ok "remote deploy completed for ${HOST_NAME}"
}

main() {
	parse_args "$@"
	[[ -n "$HOST_NAME" ]] || {
		usage >&2
		exit 1
	}

	if [[ "$REMOTE_MODE" == true ]]; then
		run_remote_workflow
		return
	fi

	run_local_workflow
}

main "$@"
