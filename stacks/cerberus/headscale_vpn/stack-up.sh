#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
	cat <<'EOF'
Usage: stack-up.sh

Run stack-local follow-up tasks after `bin/up.sh` starts this stack.
EOF
}

is_help_request() {
	case "${1:-}" in
	-h | --help)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

if is_help_request "${1:-}"; then
	usage
	exit 0
fi

if [[ -x "${SCRIPT_DIR}/seed-users.sh" ]]; then
	"${SCRIPT_DIR}/seed-users.sh"
fi
