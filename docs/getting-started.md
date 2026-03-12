# Getting Started

This is the canonical operator workflow for the repo.

## Choose A Working Style

You can operate the repo in three simple ways:

- local repo on your machine, then run the host lifecycle commands directly
- local repo on your machine, then use `deploy` to sync and run the remote workflow over SSH
- cloned repo on the remote host, then run the same lifecycle commands there

The lifecycle stays the same. Only where you run it changes.

## First Bring-Up

Use this when bringing up a host for the first time or after setting up a new
machine.

```text
doctor -> deploy
```

Example:

```bash
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/doctor.sh cerberus
./bin/deploy.sh cerberus
```

What each step does:

- `doctor` checks local tools, DNS tooling, and optional host env drift
- `deploy` runs `setup --refresh`, `validate-config`, `up`, and `health`

## Normal Deploy

Use this after changing tracked templates, public hostnames, or other values.

```text
deploy
```

Example:

```bash
./bin/deploy.sh cerberus
```

`deploy` is the main operator command. It refreshes tracked config, validates
it, reconciles the stack, and checks health.

## Manual Lifecycle

Use the lower-level commands only when you want to inspect or control each step
yourself.

```text
setup --refresh -> validate-config -> up -> health
```

```bash
./bin/setup.sh --refresh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

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
helpers/install-ssh-key -> deploy --remote
```

Example:

```bash
./bin/helpers/install-ssh-key.sh root@cerberus.raulcorreia.dev
./bin/deploy.sh --remote root@cerberus.raulcorreia.dev cerberus
```

Notes:

- `deploy --remote` syncs the repo, then runs `deploy` on the remote host
- use `./bin/helpers/sync.sh` directly only when you want to push files without running the remote workflow
- keep files like `stacks/<host>/.env`, `dns/.env`, and `dns/creds.json` local to the remote machine

## Run Directly On The Remote Host

If you prefer to clone the repo on the remote host and work there, use the same
lifecycle commands directly on that machine:

```bash
git pull
./bin/doctor.sh cerberus
./bin/deploy.sh cerberus
```

This is often the simplest path when you are already logged into the host.

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
