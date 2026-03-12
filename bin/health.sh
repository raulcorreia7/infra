#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""
declare -a ENABLED_STACKS=()

usage() {
	cat <<'EOF'
Usage: bin/health.sh <host>

Run basic runtime health checks for one host.

Options:
  -h, --help Show this help.
EOF
}

print_heading() {
	printf '\n== %s ==\n' "$1"
}

run_stack_health_script() {
	local stack_name="$1"
	local script_path=""

	script_path="$(stack_script_path "$stack_name" "stack-health.sh")"
	[[ -x "$script_path" ]] || return 0

	print_heading "${stack_name}: stack health"
	"$script_path"
}

verify_stack_status() {
	local stack_name="$1"
	print_heading "${stack_name}: docker compose ps"
	run_compose "$stack_name" ps
}

verify_headscale_stack() {
	is_enabled_stack headscale_vpn || return

	print_heading 'headscale_vpn: headscale health'
	run_compose headscale_vpn exec -T headscale headscale health

	print_heading 'headscale_vpn: headscale configtest'
	run_compose headscale_vpn exec -T headscale headscale configtest

	print_heading 'headscale_vpn: headscale logs'
	run_compose headscale_vpn logs --tail 100 headscale

	print_heading 'headscale_vpn: headplane logs'
	run_compose headscale_vpn logs --tail 100 headplane
}

verify_reverse_proxy_stack() {
	is_enabled_stack reverse_proxy || return

	print_heading 'reverse_proxy: recent caddy logs'
	run_compose reverse_proxy logs --tail 100 caddy
}

verify_public_endpoints() {
	[[ -n "${PUBLIC_FQDN:-}" ]] || return

	print_heading "curl: https://${PUBLIC_FQDN}/health"
	curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/health"

	print_heading "curl: https://${PUBLIC_FQDN}/admin"
	curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/admin"

	if [[ -n "${PUBLIC_FQDN_COMPAT:-}" && "${PUBLIC_FQDN_COMPAT}" != "${PUBLIC_FQDN}" ]]; then
		print_heading "curl: https://${PUBLIC_FQDN_COMPAT}/health"
		curl -I --fail --silent --show-error "https://${PUBLIC_FQDN_COMPAT}/health"

		print_heading "curl: https://${PUBLIC_FQDN_COMPAT}/admin"
		curl -I --fail --silent --show-error "https://${PUBLIC_FQDN_COMPAT}/admin"
	fi
}

main() {
	if is_help_flag "$HOST_NAME"; then
		usage
		return
	fi

	if [[ -z "$HOST_NAME" ]]; then
		usage >&2
		exit 1
	fi

	set_host_paths
	require_local_env_file
	load_host_env
	load_enabled_stacks

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	require_command curl
	require_command docker
	require_docker_compose

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		verify_stack_status "$stack_name"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		run_stack_health_script "$stack_name"
	done

	verify_headscale_stack
	verify_reverse_proxy_stack
	verify_public_endpoints
}

main "$@"
