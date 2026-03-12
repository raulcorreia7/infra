# Infra

Small homelab infra repo built around Docker Compose, Caddy, and host-first
rendered config.

The repo is meant to feel boring in a good way:

- `stacks/<host>/.env` is the source of truth
- `setup` renders or copies local files only when needed
- plain `docker compose` still works inside each stack directory
- public traffic follows `Internet -> Caddy -> internal service`

## Working Styles

Use whichever style fits the job:

- local repo on your machine, running the lifecycle commands directly
- local repo on your machine, deploying to a remote host with `deploy`
- cloned repo on the remote host, then running the same lifecycle commands there

## Operator Flows

First bring-up on the current machine:

```bash
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/doctor.sh cerberus
./bin/deploy.sh cerberus
```

Tracked template or hostname change:

```bash
./bin/deploy.sh cerberus
```

Remote deploy:

```bash
./bin/helpers/install-ssh-key.sh root@cerberus.raulcorreia.dev
./bin/deploy.sh --remote root@cerberus.raulcorreia.dev cerberus
```

Same workflow after cloning on the remote host:

```bash
git pull
./bin/deploy.sh cerberus
```

DNS change:

```bash
./bin/helpers/install-dnscontrol.sh
./bin/dnscontrol preview
./bin/dnscontrol push
```

Stop or remove a host:

```bash
./bin/down.sh cerberus
./bin/teardown.sh cerberus
./bin/teardown.sh --remove cerberus
```

## Current Hosts

- `cerberus` is the public edge host
- `athena` is the Proxmox hypervisor host
- `daedalus` is the internal Docker app host VM
- `chronos` is the storage placeholder host

Current public names:

- `vpn.raulcorreia.dev` -> canonical Headscale and Headplane URL
- `tailscale.cerberus.raulcorreia.dev` -> temporary compatibility alias
- `*.home.arpa` -> private homelab names over the tailnet and homelab DNS path

## Core Commands

Daily workflow:

- `./bin/doctor.sh [host]`
- `./bin/deploy.sh <host>`
- `./bin/deploy.sh --remote [user@]host <host> [--path path]`
- `./bin/logs.sh <host> [stack]`
- `./bin/down.sh <host>`
- `./bin/teardown.sh <host>`
- `./bin/teardown.sh --remove <host>`

Remote and DNS:

- `./bin/dnscontrol <command>`

## Helper Commands

Helper-only scripts live under `bin/helpers/` so the main `bin/` surface stays
focused on day-to-day operator commands.

Bootstrap and one-time setup:

- `./bin/helpers/install-ssh-key.sh [user@]host`
- `./bin/helpers/install-dnscontrol.sh`

Advanced manual lifecycle:

- `./bin/setup.sh <host>`
- `./bin/setup.sh --refresh <host>`
- `./bin/validate-config.sh <host>`
- `./bin/up.sh <host>`
- `./bin/health.sh <host>`

Advanced remote helper:

- `./bin/helpers/sync.sh [user@]host [--path path]`

Quality:

- `./bin/helpers/fmt.sh`
- `./bin/helpers/lint.sh`

## Plain Compose

After `setup`, each enabled stack gets a generated local `.env` file. That file
includes both the stack's allowed env values and `COMPOSE_PROJECT_NAME`, so
plain `docker compose` inside the stack directory uses the same host-scoped
project name as the repo scripts.

Example:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
```

## Where To Read Next

- `docs/index.md` for the operator map
- `docs/getting-started.md` for the canonical bring-up workflow
- `docs/cheatsheet.md` for the shortest useful commands
- `docs/homelab.md` for topology and routing
- `docs/tailscale.md` for Headscale quick start and client migration
- `dns/README.md` for Cloudflare DNSControl workflow
