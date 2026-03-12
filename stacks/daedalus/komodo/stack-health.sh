#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd -- "$SCRIPT_DIR"

curl -k --fail --silent --show-error "https://${KOMODO_HOST}" >/dev/null
docker compose ps
