# Infra

Small host-scoped infrastructure monorepo built around Docker Compose, Caddy,
and a render-once config workflow.

## Purpose

This repo keeps one folder per host and one folder per stack. The active host is
`cerberus`, which currently runs:

- `reverse_proxy` for public HTTPS and routing
- `headscale_vpn` for Headscale and Headplane

The goal is low-friction bring-up on a new server: copy the repo, review the
host config, run setup once, then start the enabled stacks.

The current `cerberus` defaults also seed the Headscale users `gil` and `raul`
after startup.

## Quick Start

```bash
bash bin/setup.sh cerberus

# review local config files rendered from hosts/cerberus/.env
$EDITOR stacks/reverse_proxy/config/Caddyfile
$EDITOR stacks/headscale_vpn/config/headscale/config.yaml
$EDITOR stacks/headscale_vpn/config/headplane/config.yaml

bash bin/up.sh cerberus
bash bin/verify.sh cerberus
```

To stop everything later:

```bash
bash bin/down.sh cerberus
```

## Repo Layout

- `bin/` holds the root lifecycle scripts.
- `docs/` holds topology and architecture notes.
- `hosts/` holds host identity and enabled stack lists.
- `stacks/headscale_vpn/` holds Headscale, Headplane, config templates, and local data.
- `stacks/reverse_proxy/` holds Caddy, routing config, and local TLS state.

## Architecture

- `docs/homelab.md` documents the current homelab, public entrypoint, internal
  Docker network layout, and request flow with ASCII diagrams.

## Guide

Use this flow on a new machine or after a local reset:

1. Copy the repo.
2. Review `hosts/<host>/.env.example` and create `hosts/<host>/.env` if needed.
3. Enable stacks in `hosts/<host>/stacks.txt`.
4. Run `bash bin/setup.sh <host>` to render any missing host-driven config files.
5. Review the local config files rendered from the host env.
6. Run `bash bin/up.sh <host>`.
7. Run `bash bin/verify.sh <host>`.

## Bring-Up Flow

1. Review `hosts/<host>/.env` and `hosts/<host>/stacks.txt`.
2. Run `bash bin/setup.sh <host>` to validate dependencies, create the external
   Docker network, create missing data directories, render any missing
   `*.template` files, and copy any missing `*.example` files.
3. Edit the rendered local config files if needed.
4. Run `bash bin/up.sh <host>` to start `reverse_proxy` first and the remaining
   stacks after that.
5. Use `bash bin/logs.sh <host> [stack]` and `bash bin/verify.sh <host>` to
   inspect the running services.
6. Run `bash bin/down.sh <host>` to stop the host cleanly.

For `cerberus`, the domain defaults are already in `hosts/cerberus/.env.example`.
Fill in the remaining local values before the first bring-up.

## Enable a Stack

`hosts/<host>/stacks.txt` is the source of truth. Add one stack directory name
per line:

```text
reverse_proxy
headscale_vpn
```

Rules:

- Blank lines are ignored.
- Lines starting with `#` are comments.
- `reverse_proxy` should stay enabled for hosts that expose public services.
- Stack names must match real directories under `stacks/`.

## Add a New Host

1. Create `hosts/<host>/`.
2. Add `hosts/<host>/.env.example`.
3. Copy it to `hosts/<host>/.env` locally.
4. Add `hosts/<host>/stacks.txt`.
5. Run `bash bin/setup.sh <host>`.

The host env is intentionally small. It should define the host identity, public
DNS details, timezone, and the shared edge network name.

### Proxmox notes

The current `proxmox` placeholder is meant for a lightweight Alpine LXC built
with Proxmox VE community scripts, then extended with Tailscale.

- Alpine LXC bootstrap:

```bash
var_cpu="2" var_disk="2" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/alpine.sh)"
```

- Tailscale addon:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh)"
```

- Reference pages:
  - `https://community-scripts.org/scripts/alpine`
  - `https://community-scripts.org/scripts/add-tailscale-lxc`

## Copy/Edit Workflow

`bash bin/setup.sh <host>` keeps `hosts/<host>/.env` as the single source of
truth for host-specific values.

When a stack has tracked templates, setup renders them only when the real local
file is missing.

Examples:

- `.env.example` -> `.env`
- `config.template.yaml` -> `config.yaml`
- `policy.example.yaml` -> `policy.yaml`
- `Caddyfile.template` -> `Caddyfile`

Existing local files are never overwritten.

If `HEADPLANE_COOKIE_SECRET` is not set in `hosts/<host>/.env`, setup generates
a 32-character secret from `openssl rand -hex 16` the first time it renders
Headplane config.

## Access Rule

Use the reverse proxy stack as the normal public entrypoint. Application stacks
should stay internal by default and only publish direct ports for short-lived
testing.

## Commands

| Command | Purpose |
| --- | --- |
| `bash bin/setup.sh <host>` | Validate prerequisites, create the shared Docker network, create missing runtime directories, render host-driven config templates, and copy any static starter files. |
| `bash bin/up.sh <host>` | Start `reverse_proxy` first, then start the remaining enabled stacks in host order. |
| `bash bin/down.sh <host>` | Stop non-proxy stacks in reverse order, then stop `reverse_proxy` last. |
| `bash bin/logs.sh <host> [stack]` | Follow logs for one stack or all enabled stacks. |
| `bash bin/verify.sh <host>` | Show Compose status, run Headscale checks, show recent service logs, and probe the public `/health` and `/admin` endpoints. |
| `bash bin/fmt.sh` | Format tracked shell scripts with `shfmt` or a Docker fallback. |
| `bash bin/lint.sh` | Lint tracked shell scripts with `shellcheck` or a Docker fallback. |
| `bash bin/validate.sh [host]` | Render templates for a host in a temp directory and validate shell, Compose, and Caddy config. |

## Stack Notes

- `stacks/headscale_vpn/README.md` covers Headscale, Headplane, API keys, and
  enrollment.
- `stacks/reverse_proxy/README.md` covers Caddy, TLS storage, and public route
  ownership.
