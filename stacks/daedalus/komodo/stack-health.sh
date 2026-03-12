#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd -- "$SCRIPT_DIR"

if ! curl -k --fail --silent --show-error "https://${KOMODO_HOST}" >/dev/null; then
	curl --fail --silent --show-error "http://127.0.0.1:9120" >/dev/null
fi

docker compose ps
