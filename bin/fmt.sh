#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

usage() {
	cat <<'EOF'
Usage: bin/fmt.sh

Format tracked shell scripts with shfmt or a Docker fallback.

Options:
  -h, --help Show this help.
EOF
}

run_shfmt() {
	if command -v shfmt >/dev/null 2>&1; then
		shfmt "$@"
		return
	fi

	docker run --rm \
		-v "${ROOT_DIR}:/workdir" \
		-w /workdir \
		mvdan/shfmt:v3.10.0 \
		shfmt "$@"
}

main() {
	if is_help_flag "${1:-}"; then
		usage
		return
	fi

	require_command docker
	mapfile -t shell_files < <(list_existing_shell_files)

	if [[ "${#shell_files[@]}" -eq 0 ]]; then
		printf 'no shell files to format\n'
		return
	fi

	run_shfmt -w "${shell_files[@]}"
}

main "$@"
