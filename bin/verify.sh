#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
STACKS_FILE=""
PUBLIC_FQDN=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/verify.sh <host>

Run basic status and health checks for one host.
EOF
}

fail() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

require_host_name() {
	[[ -n "$HOST_NAME" ]] || {
		usage >&2
		exit 1
	}
}

set_host_paths() {
	HOST_DIR="${ROOT_DIR}/hosts/${HOST_NAME}"
	ENV_FILE="${HOST_DIR}/.env"
	STACKS_FILE="${HOST_DIR}/stacks.txt"

	[[ -d "$HOST_DIR" ]] || fail "unknown host '${HOST_NAME}' (missing ${HOST_DIR})"
	[[ -f "$STACKS_FILE" ]] || fail "missing stacks file: ${STACKS_FILE}"
	[[ -f "$ENV_FILE" ]] || fail "missing ${ENV_FILE}; copy ${HOST_DIR}/.env.example to ${ENV_FILE} first"
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_docker_compose() {
	docker compose version >/dev/null 2>&1 || fail "docker compose is required"
}

load_host_env() {
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
}

load_enabled_stacks() {
	local raw_line=""
	local stack_name=""

	ENABLED_STACKS=()

	while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
		stack_name="${raw_line%%#*}"
		stack_name="$(trim "$stack_name")"

		[[ -n "$stack_name" ]] || continue
		ENABLED_STACKS+=("$stack_name")
	done <"$STACKS_FILE"
}

stack_dir() {
	printf '%s/stacks/%s' "$ROOT_DIR" "$1"
}

run_compose() {
	local stack_name="$1"
	shift
	local directory

	directory="$(stack_dir "$stack_name")"
	[[ -d "$directory" ]] || fail "missing stack directory: ${directory}"

	(
		cd -- "$directory"
		docker compose --project-name "${HOST_NAME}_${stack_name}" "$@"
	)
}

is_enabled_stack() {
	local candidate="$1"
	local stack_name=""

	for stack_name in "${ENABLED_STACKS[@]}"; do
		[[ "$stack_name" == "$candidate" ]] && return 0
	done

	return 1
}

print_heading() {
	printf '\n== %s ==\n' "$1"
}

verify_stack_status() {
	local stack_name="$1"
	print_heading "${stack_name}: docker compose ps"
	run_compose "$stack_name" ps
}

verify_headscale() {
	is_enabled_stack headscale_vpn || return

	print_heading 'headscale_vpn: headscale health'
	run_compose headscale_vpn exec -T headscale headscale health

	print_heading 'headscale_vpn: headscale configtest'
	run_compose headscale_vpn exec -T headscale headscale configtest

	print_heading 'headscale_vpn: headscale logs'
	run_compose headscale_vpn logs --tail 100 headscale
}

verify_headplane() {
	is_enabled_stack headscale_vpn || return

	print_heading 'headscale_vpn: headplane logs'
	run_compose headscale_vpn logs --tail 100 headplane
}

verify_reverse_proxy() {
	is_enabled_stack reverse_proxy || return

	print_heading 'reverse_proxy: recent caddy logs'
	run_compose reverse_proxy logs --tail 100 caddy
}

verify_public_endpoints() {
	[[ -n "${PUBLIC_FQDN:-}" ]] || fail "PUBLIC_FQDN must be set in ${ENV_FILE}"

	print_heading "curl: https://${PUBLIC_FQDN}/health"
	curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/health"

	print_heading "curl: https://${PUBLIC_FQDN}/admin"
	curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/admin"
}

main() {
	require_host_name
	set_host_paths
	require_command docker
	require_command curl
	require_docker_compose
	load_host_env
	load_enabled_stacks

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		verify_stack_status "$stack_name"
	done

	verify_headscale
	verify_headplane
	verify_reverse_proxy
	verify_public_endpoints
}

main "$@"
