#!/usr/bin/env bash
set -euo pipefail

SEED_USERS_RAW="${HEADSCALE_SEED_USERS:-}"
declare -a SEED_USERS=()

load_seed_users() {
	local entry=""

	[[ -n "$SEED_USERS_RAW" ]] || return

	IFS=',' read -r -a SEED_USERS <<<"$SEED_USERS_RAW"

	for entry_index in "${!SEED_USERS[@]}"; do
		entry="${SEED_USERS[entry_index]}"
		entry="${entry#${entry%%[![:space:]]*}}"
		entry="${entry%${entry##*[![:space:]]}}"
		SEED_USERS[entry_index]="$entry"
	done
}

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

	load_seed_users

	if [[ "${#SEED_USERS[@]}" -eq 0 ]]; then
		printf 'no seed users configured\n'
		return
	fi

	wait_for_headscale

	for user_name in "${SEED_USERS[@]}"; do
		ensure_user "$user_name"
	done
}

main "$@"
