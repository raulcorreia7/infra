#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

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
	require_command docker
	mapfile -t shell_files < <(git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard '*.sh')

	if [[ "${#shell_files[@]}" -eq 0 ]]; then
		printf 'no shell files to lint\n'
		return
	fi

	run_shellcheck --shell=bash --severity=warning "${shell_files[@]}"
}

main "$@"
