# Infra

Small homelab infra repo built around Docker Compose, Caddy, and host-driven
rendered config.

## What This Repo Is

- One top-level folder per host under `stacks/`
- One folder per service stack inside each host
- `cerberus` is the current public edge
- `reverse_proxy` fronts public traffic
- `headscale_vpn` runs Headscale + Headplane

## Quick Start

```bash
bash bin/setup.sh cerberus
bash bin/validate-config.sh cerberus
bash bin/up.sh cerberus
bash bin/verify-runtime.sh cerberus
```

Stop everything:

```bash
bash bin/down.sh cerberus
```

Remove stack resources and the shared edge network when unused:

```bash
bash bin/teardown.sh cerberus
bash bin/teardown.sh --remove cerberus
```

## Rule Of Thumb

```text
public traffic -> Caddy -> internal service
```

Keep app services internal by default. Only expose direct ports for temporary
testing.

## Commands

- `bash bin/setup.sh <host>` bootstrap host config and runtime directories
- `bash bin/install-ssh-key.sh [user@]host` install your local public SSH key on a server
- `bash bin/up.sh <host>` start enabled stacks
- `bash bin/down.sh <host>` stop enabled stacks
- `bash bin/teardown.sh <host>` remove stack resources and clean up unused host network state
- `bash bin/teardown.sh --remove <host>` also remove stack images and clear rendered runtime files
- `bash bin/logs.sh <host> [stack]` inspect logs
- `bash bin/verify-runtime.sh <host>` run post-start health checks
- `bash bin/fmt.sh` format shell scripts
- `bash bin/lint.sh` lint shell scripts
- `bash bin/validate-config.sh [host]` validate templates and stack config

## Docs

- `docs/index.md` docs map
- `docs/getting-started.md` setup flow, host model, and config rendering
- `docs/homelab.md` homelab and network topology
- `stacks/cerberus/headscale_vpn/README.md` Headscale and Headplane notes
- `stacks/cerberus/reverse_proxy/README.md` Caddy and routing notes
