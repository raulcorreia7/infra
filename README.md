# Infra

Small homelab infra repo built around Docker Compose, Caddy, and host-first
rendered config.

The repo is meant to feel boring in a good way:

- `stacks/<host>/.env` is the source of truth
- `setup` renders or copies local files only when needed
- plain `docker compose` still works inside each stack directory
- public traffic follows `Internet -> Caddy -> internal service`

## Operator Flows

First bring-up:

```bash
./bin/doctor.sh cerberus
./bin/setup.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

Tracked template or hostname change:

```bash
./bin/refresh-config.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

Remote deploy:

```bash
./bin/install-ssh-key.sh root@cerberus.raulcorreia.dev
./bin/sync.sh root@cerberus.raulcorreia.dev infra
./bin/deploy.sh root@cerberus.raulcorreia.dev cerberus infra
```

DNS change:

```bash
./bin/install-dnscontrol.sh
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

## Command Groups

Bootstrap:

- `./bin/doctor.sh [host]`
- `./bin/install-ssh-key.sh [user@]host`
- `./bin/install-dnscontrol.sh`

Host lifecycle:

- `./bin/setup.sh <host>`
- `./bin/validate-config.sh <host>`
- `./bin/up.sh <host>`
- `./bin/health.sh <host>`
- `./bin/logs.sh <host> [stack]`
- `./bin/down.sh <host>`
- `./bin/teardown.sh <host>`
- `./bin/teardown.sh --remove <host>`

Maintenance:

- `./bin/refresh-config.sh <host>`

Remote deploy:

- `./bin/sync.sh [user@]host [remote-path]`
- `./bin/deploy.sh [user@]host <host> [remote-path]`

DNS:

- `./bin/dnscontrol <command>`

Quality:

- `./bin/fmt.sh`
- `./bin/lint.sh`

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
