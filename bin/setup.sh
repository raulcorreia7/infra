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
Usage: bin/setup.sh <host>

Prepare one host for running enabled Docker Compose stacks.
EOF
}

copy_example_file_once() {
	local example_file="$1"
	local target_file=""

	target_file="$(target_path_for_example "$example_file")"
	[[ -e "$target_file" ]] && return

	cp "$example_file" "$target_file"
	printf 'created %s\n' "${target_file#"${ROOT_DIR}/"}"
}

render_template_file_once() {
	local template_file="$1"
	local target_file=""

	target_file="$(target_path_for_template "$template_file")"
	[[ -e "$target_file" ]] && return

	render_template_to_file "$template_file" "$target_file"
	printf 'rendered %s\n' "${target_file#"${ROOT_DIR}/"}"
}

ensure_edge_network() {
	[[ -n "${EDGE_NETWORK:-}" ]] || fail "EDGE_NETWORK must be set in ${ENV_FILE}"

	if docker network inspect "$EDGE_NETWORK" >/dev/null 2>&1; then
		printf 'network already present: %s\n' "$EDGE_NETWORK"
		return
	fi

	docker network create "$EDGE_NETWORK" >/dev/null
	printf 'created external network: %s\n' "$EDGE_NETWORK"
}

ensure_stack_directories() {
	local stack_name="$1"
	local stack_directory="$2"

	case "$stack_name" in
	headscale_vpn)
		mkdir -p "$stack_directory/data/headscale" "$stack_directory/data/headplane"
		printf 'ensured %s\n' "${stack_directory#"${ROOT_DIR}/"}/data/headscale"
		printf 'ensured %s\n' "${stack_directory#"${ROOT_DIR}/"}/data/headplane"
		;;
	reverse_proxy)
		mkdir -p "$stack_directory/data/caddy" "$stack_directory/data/config"
		printf 'ensured %s\n' "${stack_directory#"${ROOT_DIR}/"}/data/caddy"
		printf 'ensured %s\n' "${stack_directory#"${ROOT_DIR}/"}/data/config"
		;;
	*)
		mkdir -p "$stack_directory/data"
		printf 'ensured %s\n' "${stack_directory#"${ROOT_DIR}/"}/data"
		;;
	esac
}

prepare_stack() {
	local stack_name="$1"
	local stack_directory=""
	local template_file=""
	local example_file=""

	stack_directory="$(stack_dir "$stack_name")"

	[[ -d "$stack_directory" ]] || fail "missing stack directory: ${stack_directory}"
	ensure_stack_directories "$stack_name" "$stack_directory"

	while IFS= read -r template_file; do
		render_template_file_once "$template_file"
	done < <(find "$stack_directory" -type f \( -name '*.template' -o -name '*.template.yaml' \) | sort)

	while IFS= read -r example_file; do
		copy_example_file_once "$example_file"
	done < <(find "$stack_directory" -type f \( -name '*.example' -o -name '*.example.yaml' \) | sort)
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

	require_command docker
	require_command envsubst
	require_command openssl
	require_docker_compose
	set_host_paths
	require_local_env_file
	load_host_env
	load_enabled_stacks
	ensure_edge_network

	if [[ "${#ENABLED_STACKS[@]}" -eq 0 ]]; then
		printf 'no enabled stacks for host %s\n' "$HOST_NAME"
		return
	fi

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		prepare_stack "$stack_name"
	done
}

main "$@"
