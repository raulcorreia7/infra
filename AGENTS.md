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
- Placeholder hosts: `stacks/athena/`, `stacks/chronos/`

## Source Of Truth

- `stacks/<host>/.env` is the source of truth for host-specific values
- `*.template*` files render once into local config files during `setup`
- `*.example*` files copy once for static starter files during `setup`
- `setup` must never overwrite existing rendered or copied local files

## Runtime Rule

- Rule of thumb: `public traffic -> Caddy -> internal service`
- Keep application services internal by default
- Direct port publishing is only for temporary testing
- Shared Docker network name comes from `EDGE_NETWORK`

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

- `bash bin/setup.sh <host>`
- `bash bin/validate-config.sh <host>`
- `bash bin/up.sh <host>`
- `bash bin/health.sh <host>`
- `bash bin/down.sh <host>`
- `bash bin/teardown.sh <host>`
- `bash bin/teardown.sh --remove <host>`

Quality commands:

- `bash bin/fmt.sh`
- `bash bin/lint.sh`

## Stack-Local Behavior

- Generic lifecycle stays in `bin/`
- Stack-specific behavior stays inside the stack directory
- If a stack needs follow-up work after `up`, use `stack-up.sh`
- Current example: `stacks/cerberus/headscale_vpn/stack-up.sh`

## Version Policy

- Prefer stable/latest channels over patch-pinned image tags when practical
- Avoid unnecessary patch pinning unless there is a concrete compatibility reason

## Durable Expectations

- Keep docs concise and high-signal
- Prefer path-based ignores over extension-based ignores
- Do not introduce templating engines, orchestrators, or extra frameworks lightly
- Preserve the host-first structure unless there is a strong simplification win
