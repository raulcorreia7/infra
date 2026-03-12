#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd -- "$SCRIPT_DIR"

curl -k --fail --silent --show-error "https://${FORGEJO_HOST}/api/healthz" >/dev/null
docker compose exec -T forgejo sh -lc "ss -ltn | grep -q ':2222'"
