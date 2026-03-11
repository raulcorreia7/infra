# Infra

Small host-scoped infrastructure monorepo built around Docker Compose, Caddy,
and a copy-edit config workflow.

## Purpose

This repo keeps one folder per host and one folder per stack. The active host is
`cerberus`, which currently runs:

- `reverse_proxy` for public HTTPS and routing
- `headscale_vpn` for Headscale and Headplane

The goal is low-friction bring-up on a new server: copy the repo, review the
host config, run setup once, then start the enabled stacks.

The current `cerberus` defaults also seed the Headscale users `gil` and `raul`
after startup.

## Directory Structure

```text
infra/
├── README.md
├── .gitignore
├── bin/
│   ├── setup.sh
│   ├── up.sh
│   ├── down.sh
│   ├── logs.sh
│   └── verify.sh
├── hosts/
│   ├── cerberus/
│   │   ├── .env
│   │   ├── .env.example
│   │   └── stacks.txt
│   ├── nas/
│   │   ├── .env.example
│   │   └── stacks.txt
│   └── proxmox/
│       ├── .env.example
│       └── stacks.txt
└── stacks/
    ├── headscale_vpn/
    │   ├── README.md
    │   ├── compose.yaml
    │   ├── config/
    │   └── data/
    └── reverse_proxy/
        ├── README.md
        ├── compose.yaml
        ├── config/
        └── data/
```

## Bring-Up Flow

1. Review `hosts/<host>/.env` and `hosts/<host>/stacks.txt`.
2. Run `bash bin/setup.sh <host>` to validate dependencies, create the external
   Docker network, create missing data directories, and copy any missing
   `*.example` files to their real local counterparts.
3. Edit the copied local config files if needed.
4. Run `bash bin/up.sh <host>` to start `reverse_proxy` first and the remaining
   stacks after that.
5. Use `bash bin/logs.sh <host> [stack]` and `bash bin/verify.sh <host>` to
   inspect the running services.
6. Run `bash bin/down.sh <host>` to stop the host cleanly.

For `cerberus`, the committed defaults already target
`cerberus.raulcorreia.dev`, so the first bring-up should need only small edits
at most.

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

`bash bin/setup.sh <host>` copies stack example files only when the real file is
missing.

Examples:

- `.env.example` -> `.env`
- `config.example.yaml` -> `config.yaml`
- `policy.example.yaml` -> `policy.yaml`
- `Caddyfile.example` -> `Caddyfile`

Existing local files are never overwritten.

When `stacks/headscale_vpn/config/headplane/config.yaml` is created for the
first time, setup replaces `REPLACE_WITH_32_CHAR_SECRET` with a generated
32-character secret from `openssl rand -hex 16`.

## Commands

| Command | Purpose |
| --- | --- |
| `bash bin/setup.sh <host>` | Validate prerequisites, create the shared Docker network, create missing runtime directories, and copy missing local config files. |
| `bash bin/up.sh <host>` | Start `reverse_proxy` first, then start the remaining enabled stacks in host order. |
| `bash bin/down.sh <host>` | Stop non-proxy stacks in reverse order, then stop `reverse_proxy` last. |
| `bash bin/logs.sh <host> [stack]` | Follow logs for one stack or all enabled stacks. |
| `bash bin/verify.sh <host>` | Show Compose status, run Headscale checks, show recent service logs, and probe the public `/health` and `/admin` endpoints. |

## Stack Notes

- `stacks/headscale_vpn/README.md` covers Headscale, Headplane, API keys, and
  enrollment.
- `stacks/reverse_proxy/README.md` covers Caddy, TLS storage, and public route
  ownership.
