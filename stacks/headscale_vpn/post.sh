#!/usr/bin/env bash
set -euo pipefail

SEED_USERS=("gil" "raul")

wait_for_headscale() {
	local attempt=0
	local max_attempts=30

	until docker exec headscale headscale health >/dev/null 2>&1; do
		attempt=$((attempt + 1))
		if [[ "$attempt" -ge "$max_attempts" ]]; then
			printf 'error: headscale did not become ready in time\n' >&2
			exit 1
		fi

		sleep 2
	done
}

user_exists() {
	local user_name="$1"

	docker exec headscale headscale users list --output json |
		grep -Eq "\"name\"[[:space:]]*:[[:space:]]*\"${user_name}\""
}

ensure_user() {
	local user_name="$1"

	if user_exists "$user_name"; then
		printf 'headscale user already present: %s\n' "$user_name"
		return
	fi

	docker exec headscale headscale users create "$user_name" >/dev/null
	printf 'created headscale user: %s\n' "$user_name"
}

main() {
	local user_name=""

	wait_for_headscale

	for user_name in "${SEED_USERS[@]}"; do
		ensure_user "$user_name"
	done
}

main "$@"
