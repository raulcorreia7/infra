#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

cd -- "$SCRIPT_DIR"

if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
fi

if ! curl --fail --silent --show-error "http://127.0.0.1:9120" >/dev/null; then
	curl -k --fail --silent --show-error "https://${KOMODO_HOST}" >/dev/null
fi

docker compose ps
