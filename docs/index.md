# Docs

Use this page as the navigation hub for the repo docs.

## Table Of Contents

- [Start Here](#start-here)
- [Core Docs](#core-docs)
- [Host Docs](#host-docs)
- [Active Stack Docs](#active-stack-docs)
- [Planned Stack Notes](#planned-stack-notes)
- [Doc Rules](#doc-rules)

## Start Here

- New to the repo: `README.md`
- Bringing up a host: `docs/getting-started.md`
- Understanding the environment: `docs/homelab.md`

## Core Docs

| File | Purpose |
| --- | --- |
| `README.md` | Repo overview, command surface, and entry points |
| `docs/cheatsheet.md` | Shortest practical command reference |
| `docs/getting-started.md` | Setup flow, host model, and bring-up workflow |
| `docs/homelab.md` | Topology, routing, and location map |

## Host Docs

| File | Purpose |
| --- | --- |
| `stacks/athena/README.md` | Proxmox and VM planning notes |
| `stacks/daedalus/README.md` | Internal Docker app-host notes |

## Active Stack Docs

| File | Purpose |
| --- | --- |
| `stacks/cerberus/reverse_proxy/README.md` | Public Caddy edge on Cerberus |
| `stacks/cerberus/headscale_vpn/README.md` | Headscale and Headplane on Cerberus |
| `stacks/daedalus/reverse_proxy/README.md` | Internal Caddy ingress on Daedalus |
| `stacks/daedalus/komodo/README.md` | Komodo operator stack |
| `stacks/daedalus/forgejo/README.md` | Forgejo app stack |

## Planned Stack Notes

Planned Daedalus stacks live as one short inventory in `stacks/daedalus/README.md`.

## Doc Rules

- Prefer one short source of truth per host or stack
- Link to related docs instead of repeating topology or workflow details
- Keep placeholder planning notes merged when a stack is not active yet
