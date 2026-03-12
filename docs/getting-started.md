# Getting Started

This is the canonical operator workflow for the repo.

## First Bring-Up

Use this when bringing up a host for the first time or after setting up a new
machine.

```text
doctor -> setup -> validate-config -> up -> health
```

Example:

```bash
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/doctor.sh cerberus
./bin/setup.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

What each step does:

- `doctor` checks local tools, DNS tooling, and optional host env drift
- `setup` creates runtime directories, stack-local `.env` files, and missing rendered config
- `validate-config` checks shell syntax, Compose config, and rendered app config
- `up` reconciles the enabled stacks for that host
- `health` checks running services plus the public endpoints that matter

## Refresh Tracked Config

Use this after changing tracked templates, public hostnames, or other values
that should change rendered local config on an existing host.

```text
refresh-config -> validate-config -> up -> health
```

Example:

```bash
./bin/refresh-config.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

`refresh-config` removes rendered template outputs for the enabled stacks, then
reruns `setup`. It does not remove runtime data.

## Local Stack Debugging

After `setup`, each enabled stack gets a generated local `.env` file with the
stack's allowlisted values plus `COMPOSE_PROJECT_NAME`. That keeps plain
`docker compose` usable inside the stack directory.

Example:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus

cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
docker compose -f compose.yaml -f compose.local.yaml logs -f
```

## Remote Deploy

Use SSH plus `rsync` when you want to manage a remote host from your local copy
of the repo without cloning on the server.

```text
install-ssh-key -> sync -> deploy
```

Example:

```bash
./bin/install-ssh-key.sh root@cerberus.raulcorreia.dev
./bin/sync.sh root@cerberus.raulcorreia.dev infra
./bin/deploy.sh root@cerberus.raulcorreia.dev cerberus infra
```

Notes:

- `sync` copies tracked repo files and skips remote-local secrets, rendered config, and runtime data
- `deploy` already runs `sync`, `doctor`, `refresh-config`, `validate-config`, `up`, and `health` on the remote host
- keep files like `stacks/<host>/.env`, `dns/.env`, and `dns/creds.json` local to the remote machine

## Stop And Cleanup

Use the smallest cleanup step that matches the job.

```text
logs -> down -> teardown -> teardown --remove
```

Commands:

```bash
./bin/logs.sh cerberus
./bin/down.sh cerberus
./bin/teardown.sh cerberus
./bin/teardown.sh --remove cerberus
```

- `down` stops enabled stacks
- `teardown` removes compose resources but keeps rendered config and bind-mounted data
- `teardown --remove` also removes images and rendered runtime files

## Hosts

- `cerberus` is the active public edge and runs `reverse_proxy` plus `headscale_vpn`
- `athena` is the Proxmox hypervisor host
- `daedalus` is the internal Docker app host VM
- `chronos` is the storage placeholder host

Current public names:

- `vpn.raulcorreia.dev` for the public Headscale entrypoint
- `tailscale.cerberus.raulcorreia.dev` as a temporary compatibility alias
- `*.home.arpa` for private homelab access
- future public `*.raulcorreia.dev` apps through Cerberus

## Related Docs

- `docs/cheatsheet.md` for the shortest commands
- `docs/homelab.md` for topology and routing
- `docs/tailscale.md` for client onboarding and migration
