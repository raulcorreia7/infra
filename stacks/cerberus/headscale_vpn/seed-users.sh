#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

SEED_USERS_RAW="${HEADSCALE_SEED_USERS:-}"
declare -a SEED_USERS=()

usage() {
	cat <<'EOF'
Usage: seed-users.sh

Create Headscale users listed in HEADSCALE_SEED_USERS when they are missing.
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

	if is_help_request "${1:-}"; then
		usage
		return
	fi

	if [[ -f "$ENV_FILE" ]]; then
		set -a
		# shellcheck disable=SC1090
		. "$ENV_FILE"
		set +a
		SEED_USERS_RAW="${HEADSCALE_SEED_USERS:-}"
	fi

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
