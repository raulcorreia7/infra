#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

SSH_PORT="22"
SSH_TARGET=""
PUBLIC_KEY_PATH=""
GENERATE_KEY=false

usage() {
	cat <<'EOF'
Usage: bin/install-ssh-key.sh [options] [user@]host

Install a local public SSH key on a remote server for passwordless access.

Options:
  -k, --key PATH    Public key file to install.
  -p, --port PORT   SSH port (default: 22).
  -g, --generate    Generate `~/.ssh/id_ed25519` when no default key exists.
  -h, --help        Show this help.

Examples:
  bin/install-ssh-key.sh root@example.com
  bin/install-ssh-key.sh -p 2222 user@host
  bin/install-ssh-key.sh -k ~/.ssh/id_ed25519.pub root@cerberus
EOF
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		-k | --key)
			[[ "$#" -ge 2 ]] || fail "missing value for $1"
			PUBLIC_KEY_PATH="$2"
			shift 2
			;;
		-p | --port)
			[[ "$#" -ge 2 ]] || fail "missing value for $1"
			SSH_PORT="$2"
			shift 2
			;;
		-g | --generate)
			GENERATE_KEY=true
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		-*)
			fail "unknown option: $1"
			;;
		*)
			if [[ -z "$SSH_TARGET" ]]; then
				SSH_TARGET="$1"
				shift
				continue
			fi

			fail "unexpected argument: $1"
			;;
		esac
	done
}

pick_default_key() {
	local candidate=""

	for candidate in \
		"${HOME}/.ssh/id_ed25519.pub" \
		"${HOME}/.ssh/id_ecdsa.pub" \
		"${HOME}/.ssh/id_rsa.pub"; do
		[[ -f "$candidate" ]] || continue
		PUBLIC_KEY_PATH="$candidate"
		return
	done
}

ensure_public_key() {
	if [[ -n "$PUBLIC_KEY_PATH" ]]; then
		[[ -f "$PUBLIC_KEY_PATH" ]] || fail "missing public key: $PUBLIC_KEY_PATH"
		return
	fi

	pick_default_key

	if [[ -n "$PUBLIC_KEY_PATH" ]]; then
		return
	fi

	if [[ "$GENERATE_KEY" != true ]]; then
		fail "no default public key found; use --key or --generate"
	fi

	require_command ssh-keygen
	ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -N ""
	PUBLIC_KEY_PATH="${HOME}/.ssh/id_ed25519.pub"
}

install_with_ssh_copy_id() {
	ssh-copy-id -i "$PUBLIC_KEY_PATH" -p "$SSH_PORT" "$SSH_TARGET"
}

install_with_ssh() {
	local public_key=""

	public_key="$(<"$PUBLIC_KEY_PATH")"
	ssh -p "$SSH_PORT" "$SSH_TARGET" \
		"umask 077 && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF '$public_key' ~/.ssh/authorized_keys || printf '%s\n' '$public_key' >> ~/.ssh/authorized_keys"
}

main() {
	parse_args "$@"
	[[ -n "$SSH_TARGET" ]] || {
		usage >&2
		exit 1
	}

	require_command ssh
	ensure_public_key

	if command -v ssh-copy-id >/dev/null 2>&1; then
		install_with_ssh_copy_id
	else
		install_with_ssh
	fi

	printf 'installed %s on %s\n' "$PUBLIC_KEY_PATH" "$SSH_TARGET"
}

main "$@"
