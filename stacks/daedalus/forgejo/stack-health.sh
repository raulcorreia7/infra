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

if ! curl --fail --silent --show-error "http://127.0.0.1:3000/api/healthz" >/dev/null; then
	curl -k --fail --silent --show-error "https://${FORGEJO_HOST}/api/healthz" >/dev/null
fi

docker compose exec -T forgejo ss -ltn | grep -q ':2222'
