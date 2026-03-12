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

run_quiet_check() {
	local label="$1"
	shift
	local output_file=""
	output_file="$(mktemp)"

	if "$@" >"$output_file" 2>&1; then
		rm -f "$output_file"
		log_ok "$label"
		return 0
	fi

	log_fail "$label"
	cat "$output_file" >&2
	rm -f "$output_file"
	return 1
}

run_stack_health_script() {
	local stack_name="$1"
	local script_path=""

	script_path="$(stack_script_path "$stack_name" "stack-health.sh")"
	[[ -x "$script_path" ]] || return 0

	run_quiet_check "${stack_name}: stack health" "$script_path"
}

verify_stack_status() {
	local stack_name="$1"
	local expected_services=""
	local running_services=""

	expected_services="$(run_compose "$stack_name" config --services | sort)"
	running_services="$(run_compose "$stack_name" ps --services --status running | sort)"

	if [[ "$expected_services" == "$running_services" ]]; then
		log_ok "${stack_name}: all services running"
		return 0
	fi

	log_fail "${stack_name}: service status mismatch"
	printf 'expected services:\n%s\n' "$expected_services" >&2
	printf 'running services:\n%s\n' "$running_services" >&2
	run_compose "$stack_name" ps >&2 || true
	return 1
}

dump_service_logs() {
	local stack_name="$1"
	local service_name="$2"

	printf '\n-- %s: %s logs --\n' "$stack_name" "$service_name" >&2
	run_compose "$stack_name" logs --tail 100 "$service_name" >&2 || true
}

verify_headscale_stack() {
	is_enabled_stack headscale_vpn || return

	if ! run_quiet_check 'headscale_vpn: headscale health' run_compose headscale_vpn exec -T headscale headscale health; then
		dump_service_logs headscale_vpn headscale
		dump_service_logs headscale_vpn headplane
		return 1
	fi

	if ! run_quiet_check 'headscale_vpn: headscale configtest' run_compose headscale_vpn exec -T headscale headscale configtest; then
		dump_service_logs headscale_vpn headscale
		dump_service_logs headscale_vpn headplane
		return 1
	fi
}

verify_public_endpoints() {
	[[ -n "${PUBLIC_FQDN:-}" ]] || return

	run_quiet_check "curl: https://${PUBLIC_FQDN}/health" curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/health"

	run_quiet_check "curl: https://${PUBLIC_FQDN}/admin" curl -I --fail --silent --show-error "https://${PUBLIC_FQDN}/admin"

	if [[ -n "${PUBLIC_FQDN_COMPAT:-}" && "${PUBLIC_FQDN_COMPAT}" != "${PUBLIC_FQDN}" ]]; then
		run_quiet_check "curl: https://${PUBLIC_FQDN_COMPAT}/health" curl -I --fail --silent --show-error "https://${PUBLIC_FQDN_COMPAT}/health"

		run_quiet_check "curl: https://${PUBLIC_FQDN_COMPAT}/admin" curl -I --fail --silent --show-error "https://${PUBLIC_FQDN_COMPAT}/admin"
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

	print_section "Health"
	log_step "checking ${HOST_NAME}"

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		verify_stack_status "$stack_name"
	done

	for stack_name in "${ENABLED_STACKS[@]}"; do
		run_stack_health_script "$stack_name"
	done

	verify_headscale_stack
	verify_public_endpoints
	log_ok "health checks passed for ${HOST_NAME}"
}

main "$@"
