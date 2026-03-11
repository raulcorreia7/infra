#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bin/lib/common.sh
. "${ROOT_DIR}/bin/lib/common.sh"

HOST_NAME="${1:-cerberus}"
HOST_DIR=""
ENV_FILE=""
declare -a ENABLED_STACKS=()

TEMP_DIR=""

usage() {
	cat <<'EOF'
Usage: bin/validate-config.sh [host]

Run preflight validation for rendered templates, shell scripts, and Compose
config. Defaults to `cerberus` when no host is provided.
EOF
}

cleanup() {
	[[ -n "$TEMP_DIR" ]] || return
	rm -rf "$TEMP_DIR"
}

load_validation_env() {
	local env_source="${HOST_DIR}/.env"

	if [[ ! -f "$env_source" ]]; then
		env_source="${HOST_DIR}/.env.example"
	fi

	[[ -f "$env_source" ]] || fail "missing host env file for ${HOST_NAME}"
	ENV_FILE="$env_source"
	load_host_env
}

validate_shell_syntax() {
	mapfile -t shell_files < <(list_existing_shell_files)
	[[ "${#shell_files[@]}" -gt 0 ]] || return
	bash -n "${shell_files[@]}"
}

render_templates_for_stack() {
	local stack_name="$1"
	local stack_directory=""
	local template_file=""
	local target_file=""
	local temp_target=""

	stack_directory="$(stack_dir "$stack_name")"

	while IFS= read -r template_file; do
		target_file="$(target_path_for_template "$template_file")"
		temp_target="${TEMP_DIR}/${target_file#"${ROOT_DIR}/"}"
		mkdir -p "$(dirname -- "$temp_target")"
		render_template_to_file "$template_file" "$temp_target"
		if grep -q '\${[A-Z0-9_][A-Z0-9_]*}' "$temp_target"; then
			fail "unresolved template variables in ${template_file#"${ROOT_DIR}/"}"
		fi
	done < <(find "$stack_directory" -type f \( -name '*.template' -o -name '*.template.yaml' \) | sort)
}

validate_compose_files() {
	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		run_compose "$stack_name" config >/dev/null
	done
}

validate_caddy_config() {
	local rendered_caddy="${TEMP_DIR}/stacks/${HOST_NAME}/reverse_proxy/config/Caddyfile"
	[[ -f "$rendered_caddy" ]] || return

	docker run --rm \
		-v "$rendered_caddy:/etc/caddy/Caddyfile:ro" \
		caddy:2 \
		caddy validate --config /etc/caddy/Caddyfile >/dev/null
}

validate_headscale_config() {
	local rendered_config="${TEMP_DIR}/stacks/${HOST_NAME}/headscale_vpn/config/headscale/config.yaml"
	[[ -f "$rendered_config" ]] || return

	docker run --rm \
		-v "$rendered_config:/etc/headscale/config.yaml:ro" \
		headscale/headscale:stable \
		configtest -c /etc/headscale/config.yaml >/dev/null
}

main() {
	trap cleanup EXIT
	if is_help_flag "$HOST_NAME"; then
		usage
		return
	fi

	require_command docker
	require_command envsubst
	require_command openssl
	require_docker_compose
	set_host_paths
	load_validation_env
	load_enabled_stacks
	TEMP_DIR="$(mktemp -d)"

	validate_shell_syntax
	validate_compose_files

	local stack_name=""
	for stack_name in "${ENABLED_STACKS[@]}"; do
		render_templates_for_stack "$stack_name"
	done

	validate_caddy_config
	validate_headscale_config
	printf 'validation passed for host %s\n' "$HOST_NAME"
}

main "$@"
