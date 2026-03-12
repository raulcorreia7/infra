#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

FAIL_COUNT=0
WARN_COUNT=0

HOST_NAME="${1:-}"
HOST_DIR=""
ENV_FILE=""

usage() {
	cat <<'EOF'
Usage: bin/doctor.sh [host]

Check whether the repo has the tools and local files needed for normal use.
When a host is provided, also compare its local .env against .env.example.

Options:
  -h, --help Show this help.
EOF
}

report_ok() {
	log_ok "$1"
}

report_warn() {
	WARN_COUNT=$((WARN_COUNT + 1))
	log_warn "$1"
}

report_fail() {
	FAIL_COUNT=$((FAIL_COUNT + 1))
	log_fail "$1"
}

check_command() {
	local name="$1"
	local hint="$2"

	if command -v "$name" >/dev/null 2>&1; then
		report_ok "command available: ${name}"
	else
		report_fail "missing command: ${name} (${hint})"
	fi
}

check_docker_compose() {
	if docker compose version >/dev/null 2>&1; then
		report_ok 'docker compose available'
	else
		report_fail 'docker compose is required'
	fi
}

check_optional_with_docker_fallback() {
	local name="$1"

	if command -v "$name" >/dev/null 2>&1; then
		report_ok "command available: ${name}"
		return
	fi

	if command -v docker >/dev/null 2>&1; then
		report_warn "${name} not installed locally; Docker fallback will be used"
		return
	fi

	report_fail "missing ${name} and Docker fallback is unavailable"
}

check_dns_tool() {
	local binary_path="${ROOT_DIR}/tools/dnscontrol/dnscontrol"

	if [[ ! -x "$binary_path" ]]; then
		report_warn 'dnscontrol not installed; run ./bin/helpers/install-dnscontrol.sh'
		return
	fi

	if "$binary_path" version >/dev/null 2>&1; then
		report_ok 'dnscontrol installed'
	else
		report_fail 'dnscontrol exists but does not run cleanly'
	fi
}

check_dns_files() {
	local dns_env="${ROOT_DIR}/dns/.env"
	local dns_creds="${ROOT_DIR}/dns/creds.json"
	local dns_config="${ROOT_DIR}/dns/dnsconfig.js"

	if [[ -f "$dns_config" ]]; then
		report_ok 'dns/dnsconfig.js present'
	else
		report_warn 'missing dns/dnsconfig.js'
	fi

	if [[ -f "$dns_env" ]]; then
		report_ok 'dns/.env present'
	else
		report_warn 'missing dns/.env; copy dns/.env.example'
	fi

	if [[ -f "$dns_creds" ]]; then
		report_ok 'dns/creds.json present'
	else
		report_warn 'missing dns/creds.json; copy dns/creds.json.example'
	fi

	if [[ -f "$dns_env" ]]; then
		set -a
		# shellcheck disable=SC1090
		. "$dns_env"
		set +a

		if [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
			report_ok 'CLOUDFLARE_ACCOUNT_ID set'
		else
			report_warn 'missing CLOUDFLARE_ACCOUNT_ID in dns/.env'
		fi

		if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
			report_ok 'CLOUDFLARE_API_TOKEN set'
		else
			report_warn 'missing CLOUDFLARE_API_TOKEN in dns/.env'
		fi
	fi
}

main() {
	if is_help_flag "$HOST_NAME"; then
		usage
		return
	fi

	print_section 'Core'
	check_command git 'needed for tracked-file workflows'
	check_command docker 'needed for compose, validation, and tool fallbacks'
	check_docker_compose
	check_command curl 'needed for health checks and downloads'
	check_command openssl 'needed for generated secrets and TLS helpers'
	check_command envsubst 'needed for template rendering'

	print_section 'Quality'
	check_optional_with_docker_fallback shellcheck
	check_optional_with_docker_fallback shfmt

	print_section 'DNS'
	check_dns_tool
	check_dns_files

	if [[ -n "$HOST_NAME" ]]; then
		print_section 'Host'
		set_host_paths
		if [[ -f "$ENV_FILE" ]]; then
			report_ok "${ENV_FILE#"${ROOT_DIR}/"} present"
			warn_missing_env_example_keys
		else
			report_warn "missing ${ENV_FILE#"${ROOT_DIR}/"}; copy ${HOST_DIR#"${ROOT_DIR}/"}/.env.example"
		fi
	fi

	printf -- '\nsummary: %s failure(s), %s warning(s)\n' "$FAIL_COUNT" "$WARN_COUNT"
	if [[ "$FAIL_COUNT" -gt 0 ]]; then
		exit 1
	fi
}

main "$@"
