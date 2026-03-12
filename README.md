# Infra

Small homelab infra repo built around Docker Compose, Caddy, and host-first
rendered config.

Keep it boring:

- host env is the source of truth
- setup renders/copies local files once
- after that, plain `docker compose` should still work inside each stack

## Table Of Contents

- [What This Repo Does](#what-this-repo-does)
- [Quick Start](#quick-start)
- [Host Model](#host-model)
- [Commands](#commands)
- [Documentation](#documentation)

## What This Repo Does

- Keeps infra grouped by host under `stacks/`
- Enables a stack only when `stacks/<host>/<stack>/compose.yaml` exists
- Uses `stacks/<host>/.env` as the source of truth for host values
- Renders local config once during `setup` and does not overwrite existing files
- Syncs a filtered stack-local `.env` from `stack.env.keys` so direct Compose use stays simple without leaking unrelated values

Rule of thumb:

```text
public traffic -> Caddy -> internal service
```

## Quick Start

Bring up the current public host:

```bash
./bin/doctor.sh
./bin/setup.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

For local iteration, `setup` also syncs the host env into each enabled stack so
plain Compose still works:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
```

`compose.local.yaml` is tracked for stacks that benefit from easy local
debugging.

Stop or remove it:

```bash
./bin/down.sh cerberus
./bin/teardown.sh cerberus
./bin/teardown.sh --remove cerberus
```

## Host Model

- `cerberus` is the current public edge host
- `athena` is the Proxmox hypervisor host
- `daedalus` is the internal Docker app host VM
- `chronos` is the storage placeholder host

Current public DNS split:

- `vpn.raulcorreia.dev` -> Headscale and Headplane
- `tailscale.cerberus.raulcorreia.dev` -> temporary compatibility alias to `vpn.raulcorreia.dev`
- `*.home.arpa` -> private hosts and services over the homelab/tailnet path
- future public `*.raulcorreia.dev` apps -> Cerberus edge proxy

The source of truth stays in `stacks/<host>/.env`. `setup` copies that env into
each enabled stack as a filtered local `.env` based on `stack.env.keys` so
direct `docker compose` usage stays simple without exposing the full host env to
every stack.

## Commands

| Command | Purpose |
| --- | --- |
| `./bin/setup.sh <host>` | Render missing local config and create runtime directories |
| `./bin/validate-config.sh <host>` | Validate templates and stack config |
| `./bin/up.sh <host>` | Start enabled stacks |
| `./bin/health.sh <host>` | Run host and stack health checks |
| `./bin/down.sh <host>` | Stop enabled stacks |
| `./bin/teardown.sh <host>` | Remove stack resources and unused host network state |
| `./bin/teardown.sh --remove <host>` | Also remove images and rendered runtime files |
| `./bin/logs.sh <host> [stack]` | Inspect logs |
| `./bin/install-ssh-key.sh [user@]host` | Install your local public SSH key on a server |
| `./bin/sync.sh [user@]host [remote-path]` | Sync the repo to a remote host over SSH |
| `./bin/deploy.sh [user@]host <host> [remote-path]` | Sync and run the remote host workflow |
| `./bin/install-dnscontrol.sh` | Install the repo-local DNSControl binary |
| `./bin/dnscontrol <command>` | Run DNSControl from `dns/` with local env loading |
| `./bin/doctor.sh` | Validate core repo, quality, and DNS tooling |
| `./bin/fmt.sh` | Format shell scripts |
| `./bin/lint.sh` | Lint shell scripts |

## Documentation

Start at `docs/index.md`.

- `docs/index.md` - doc map and navigation hub
- `docs/cheatsheet.md` - shortest useful commands
- `docs/getting-started.md` - setup flow and host workflow
- `docs/homelab.md` - topology, routing, and network notes
- `stacks/athena/README.md` - Athena host notes
- `stacks/daedalus/README.md` - Daedalus host notes and planned stack inventory
- `stacks/cerberus/reverse_proxy/README.md` - Cerberus Caddy notes
- `stacks/cerberus/headscale_vpn/README.md` - Cerberus Headscale notes
