#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd -- "$SCRIPT_DIR"

if ! curl -k --fail --silent --show-error "https://${FORGEJO_HOST}/api/healthz" >/dev/null; then
	curl --fail --silent --show-error "http://127.0.0.1:3000/api/healthz" >/dev/null
fi

docker compose exec -T forgejo sh -lc "ss -ltn | grep -q ':2222'"
