# Daedalus

`daedalus` is the Docker VM app host that runs Compose stacks.

## Table Of Contents

- [Role](#role)
- [Access Rule](#access-rule)
- [Active Stacks](#active-stacks)
- [Planned Stacks](#planned-stacks)
- [Doc Rule](#doc-rule)
- [Related Docs](#related-docs)

## Role

It should own:

- reverse proxy
- Komodo
- Forgejo
- future runners
- future media and photo stacks

Database rule of thumb:

- no DB unless the app needs one
- SQLite when it is a good fit for a small homelab workload
- per-stack Postgres only when the app clearly benefits from it

## Access Rule

```text
admin SSH -> daedalus.home.arpa:22
web apps  -> reverse_proxy -> internal services
git SSH   -> forgejo.home.arpa:2222
```

Keep containers internal by default. Web services should be reachable through
`reverse_proxy`, not through direct published ports.

## Active Stacks

| Stack | Role |
| --- | --- |
| `reverse_proxy` | Internal Caddy entry point for `*.home.arpa` |
| `komodo` | Operator layer for Compose workloads |
| `forgejo` | Git hosting and SSH endpoint |

## Planned Stacks

| Stack | Intent |
| --- | --- |
| `homepage` | Internal dashboard |
| `forgejo_runners` | Dedicated Actions runners |
| `media_server` | Jellyfin playback stack |
| `media_automation` | Download and library automation |
| `immich` | Separate photo stack |

Planned stacks intentionally do not include `compose.yaml` yet, so they cannot
be started accidentally by the generic `bin/` workflow.

Daedalus stays internal for web traffic. If you want selected services exposed
publicly later, Cerberus can proxy them from the edge as long as it has a clean
network path back into the homelab.

## Doc Rule

Keep detailed README files for active stacks.

For planned stacks, keep only this short inventory until a real `compose.yaml`
exists or the stack needs a concrete design note.

## Related Docs

- `docs/homelab.md` for topology and traffic flow
- `stacks/daedalus/reverse_proxy/README.md` for internal ingress
- `stacks/daedalus/komodo/README.md` for the operator stack
- `stacks/daedalus/forgejo/README.md` for the first app stack
