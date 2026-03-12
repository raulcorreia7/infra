# Getting Started

This is the shortest path from a fresh clone to a running host.

## Table Of Contents

- [Workflow](#workflow)
- [Bring Up A Host](#bring-up-a-host)
- [Host Model](#host-model)
- [Current Hosts](#current-hosts)
- [Add A Host](#add-a-host)
- [Athena References](#athena-references)

## Workflow

```text
ssh key -> doctor -> host env -> setup -> validate-config -> review -> up -> health
                                                                \-> teardown
```

## Bring Up A Host

1. Copy `stacks/<host>/.env.example` to `stacks/<host>/.env`.
2. Fill in the host values.
3. Run `./bin/doctor.sh`.
4. Confirm the host has the stack folders you want enabled.
5. Run `./bin/setup.sh <host>`.
6. Run `./bin/validate-config.sh <host>`.
7. Review the rendered local config files.
8. Run `./bin/up.sh <host>`.
9. Run `./bin/health.sh <host>`.

For cleanup:

- `./bin/down.sh <host>` stops enabled stacks
- `./bin/teardown.sh <host>` removes stack resources
- `./bin/teardown.sh --remove <host>` also removes images and rendered local files

## Local Stack Debugging

After `setup`, each enabled stack gets a synced local `.env` file copied from
`stacks/<host>/.env` using that stack's `stack.env.keys` allowlist. That means
you can iterate with plain Compose from inside the stack directory without
pulling every host variable into every stack:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
```

Stacks that benefit from easy local debugging can ship a tracked
`compose.local.yaml`. Use it explicitly when you want local ports or other
developer-friendly overrides.

## Host Model

- `stacks/<host>/.env` is the source of truth for host-specific values
- `stacks/<host>/<stack>/compose.yaml` means the stack is enabled
- `*.template*` files render once when missing
- `*.example*` files copy once when missing
- Existing rendered or copied local files are never overwritten

Host-specific notes should live with the host or stack README instead of being
duplicated here.

## Current Hosts

- `cerberus` is the active public edge and currently runs `reverse_proxy` and `headscale_vpn`
- `athena` is the Proxmox hypervisor host
- `daedalus` is the internal Docker app host VM
- `chronos` is the storage placeholder host

Current name split:

- `vpn.raulcorreia.dev` for the public Headscale entrypoint
- `tailscale.cerberus.raulcorreia.dev` as a temporary compatibility alias
- `*.home.arpa` for private host and service access
- future public `*.raulcorreia.dev` apps through Cerberus

For topology and routing, use `docs/homelab.md`.

## Add A Host

1. Create `stacks/<host>/`.
2. Add `stacks/<host>/.env.example`.
3. Add one folder per enabled stack under `stacks/<host>/`.
4. Copy the example env to a local `.env`.
5. Run `./bin/setup.sh <host>`.
6. Add or update host docs if the host has a unique role.

## Athena References

`athena` remains the hypervisor. Create `daedalus` with the upstream Docker VM
helper, then install Komodo inside the VM.

For remote homelab access through the Athena subnet router, remember that Linux
clients need `tailscale set --accept-routes`, while other major Tailscale
clients accept subnet routes by default.

- Docker VM helper: `https://community-scripts.org/scripts/docker-vm`
- Komodo helper: `https://community-scripts.org/scripts/komodo`
- Alpine LXC helper: `https://community-scripts.org/scripts/alpine`
- Tailscale LXC helper: `https://community-scripts.org/scripts/add-tailscale-lxc`
