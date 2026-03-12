#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

usage() {
	cat <<'EOF'
Usage: bin/helpers/lint.sh

Lint tracked shell scripts with shellcheck or a Docker fallback.

Options:
  -h, --help Show this help.
EOF
}

run_shellcheck() {
	if command -v shellcheck >/dev/null 2>&1; then
		shellcheck "$@"
		return
	fi

	docker run --rm \
		-v "${ROOT_DIR}:/workdir" \
		-w /workdir \
		koalaman/shellcheck:stable \
		shellcheck "$@"
}

main() {
	if is_help_flag "${1:-}"; then
		usage
		return
	fi

	if ! command -v shellcheck >/dev/null 2>&1; then
		require_command docker
	fi

	mapfile -t shell_files < <(list_existing_shell_files)

	if [[ "${#shell_files[@]}" -eq 0 ]]; then
		log_step 'no shell files to lint'
		return
	fi

	print_section 'Lint'
	log_step 'linting tracked shell scripts'
	run_shellcheck --shell=bash --severity=warning "${shell_files[@]}"
	log_ok 'lint completed'
}

main "$@"
