#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -x "${SCRIPT_DIR}/seed-users.sh" ]]; then
	"${SCRIPT_DIR}/seed-users.sh"
fi
