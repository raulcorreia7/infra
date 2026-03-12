#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

DNSCONTROL_VERSION="4.36.1"
INSTALL_DIR="${ROOT_DIR}/tools/dnscontrol"
INSTALL_PATH="${INSTALL_DIR}/dnscontrol"
TEMP_DIR=""

usage() {
	cat <<'EOF'
Usage: bin/helpers/install-dnscontrol.sh

Download the pinned DNSControl release into tools/dnscontrol/.

Options:
  -h, --help Show this help.
EOF
}

detect_platform() {
	local os=""
	local arch=""
	os="$(uname -s)"
	arch="$(uname -m)"

	case "$os" in
	Linux)
		case "$arch" in
		x86_64) DNSCONTROL_ASSET="dnscontrol_${DNSCONTROL_VERSION}_linux_amd64.tar.gz" ;;
		aarch64 | arm64) DNSCONTROL_ASSET="dnscontrol_${DNSCONTROL_VERSION}_linux_arm64.tar.gz" ;;
		*) fail "unsupported architecture: ${arch}" ;;
		esac
		;;
	Darwin)
		DNSCONTROL_ASSET="dnscontrol_${DNSCONTROL_VERSION}_darwin_all.tar.gz"
		;;
	*)
		fail "unsupported operating system: ${os}"
		;;
	esac
}

verify_checksum() {
	local archive_path="$1"
	local checksums_path="$2"

	if command -v sha256sum >/dev/null 2>&1; then
		(
			cd -- "$(dirname -- "$archive_path")" || exit 1
			sha256sum -c --ignore-missing "$checksums_path"
		)
		return
	fi

	if command -v shasum >/dev/null 2>&1; then
		local expected=""
		expected="$(grep "  $(basename -- "$archive_path")$" "$checksums_path" | awk '{print $1}')"
		[[ -n "$expected" ]] || fail "missing checksum for $(basename -- "$archive_path")"
		local actual=""
		actual="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
		[[ "$actual" == "$expected" ]] || fail "checksum mismatch for $(basename -- "$archive_path")"
		return
	fi

	log_warn 'skipping checksum verification (no sha256sum or shasum)'
}

cleanup() {
	[[ -n "$TEMP_DIR" ]] || return
	rm -rf "$TEMP_DIR"
}

main() {
	trap cleanup EXIT

	if is_help_flag "${1:-}"; then
		usage
		return
	fi

	require_command curl
	require_command tar
	detect_platform

	print_section 'Install DNSControl'
	log_step "installing dnscontrol ${DNSCONTROL_VERSION}"

	local release_url="https://github.com/StackExchange/dnscontrol/releases/download/v${DNSCONTROL_VERSION}"
	local archive_url="${release_url}/${DNSCONTROL_ASSET}"
	local checksums_url="${release_url}/checksums.txt"
	TEMP_DIR="$(mktemp -d)"

	mkdir -p "$INSTALL_DIR"
	curl --fail --location --silent --show-error "$archive_url" --output "${TEMP_DIR}/${DNSCONTROL_ASSET}"
	curl --fail --location --silent --show-error "$checksums_url" --output "${TEMP_DIR}/checksums.txt"
	verify_checksum "${TEMP_DIR}/${DNSCONTROL_ASSET}" "${TEMP_DIR}/checksums.txt"
	tar -xzf "${TEMP_DIR}/${DNSCONTROL_ASSET}" -C "$INSTALL_DIR" dnscontrol
	chmod +x "$INSTALL_PATH"
	log_ok "installed dnscontrol ${DNSCONTROL_VERSION} at ${INSTALL_PATH#"${ROOT_DIR}/"}"
}

main "$@"
