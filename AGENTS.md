# AGENTS.md

Repo-specific guidance for agents working in this infra repo.

## Purpose

- Small homelab infra repo
- Docker Compose + Caddy + shell
- Keep changes simple, local, and easy to inspect

## Core Shape

- Host-first layout: `stacks/<host>/...`
- One folder per enabled stack inside each host
- A stack is enabled when `stacks/<host>/<stack>/compose.yaml` exists
- Current active public host: `stacks/cerberus/`
- Hypervisor host: `stacks/athena/`
- Docker app host: `stacks/daedalus/`
- Placeholder storage host: `stacks/chronos/`

## Source Of Truth

- `stacks/<host>/.env` is the source of truth for host-specific values
- `setup` syncs a filtered local `.env` into each enabled stack for direct Compose use
- each real stack must declare its allowed env keys in `stack.env.keys`
- `*.template*` files render once into local config files during `setup`
- `*.example*` files copy once for static starter files during `setup`
- `setup` must never overwrite existing rendered or copied local files
- the per-stack `.env` file is the one exception because it is a generated sync artifact

## Runtime Rule

- Rule of thumb: `public traffic -> Caddy -> internal service`
- Keep application services internal by default
- Direct port publishing is only for temporary testing
- Shared Docker network name comes from `EDGE_NETWORK`
- Generic `bin/` scripts target Compose hosts like `cerberus` and `daedalus`
- Keep Proxmox-specific concerns in `stacks/athena/`

## Data And State

- Runtime state lives under `stacks/<host>/<stack>/data/`
- Rendered local config lives under `stacks/<host>/<stack>/config/`
- Keep bind mounts for important state; prefer visible on-disk data over opaque volumes
- Reverse proxy state uses bind mounts too:
  - `data/caddy/`
  - `data/config/`

## Commands

Normal workflow:

```text
setup -> validate-config -> up -> health
```

Main commands:

- `./bin/setup.sh <host>`
- `./bin/validate-config.sh <host>`
- `./bin/up.sh <host>`
- `./bin/health.sh <host>`
- `./bin/down.sh <host>`
- `./bin/teardown.sh <host>`
- `./bin/teardown.sh --remove <host>`

Quality commands:

- `./bin/fmt.sh`
- `./bin/lint.sh`

## Stack-Local Behavior

- Generic lifecycle stays in `bin/`
- Stack-specific behavior stays inside the stack directory
- If a stack needs follow-up work after `up`, use `stack-up.sh`
- If a stack needs runtime checks beyond `docker compose ps`, use `stack-health.sh`
- Current example: `stacks/cerberus/headscale_vpn/stack-up.sh`

## Version Policy

- Prefer stable/latest channels over patch-pinned image tags when practical
- Major-only tags like `caddy:2`, `postgres:17`, and `mongo:8` are preferred when a stable channel is not available
- Avoid unnecessary patch pinning unless there is a concrete compatibility reason

## Durable Expectations

- Keep docs concise and high-signal
- Prefer path-based ignores over extension-based ignores
- Do not introduce templating engines, orchestrators, or extra frameworks lightly
- Preserve the host-first structure unless there is a strong simplification win
