# Reverse Proxy

This is the only web ingress on `daedalus`.

## Table Of Contents

- [Owns](#owns)
- [Current Routes](#current-routes)
- [Rule](#rule)
- [Storage](#storage)
- [Related Docs](#related-docs)

## Owns

- port `80`
- port `443`
- internal TLS for `*.home.arpa`
- hostname routing to internal app stacks

## Current Routes

- `komodo.home.arpa` -> `komodo:9120`
- `forgejo.home.arpa` -> `forgejo:3000`

## Rule

Keep app services internal and expose them here.

Do not publish direct web ports from app stacks unless you are doing temporary
testing.

## Storage

- `data/caddy/` -> certificates and Caddy runtime state
- `data/config/` -> saved Caddy config state

## Related Docs

- `stacks/daedalus/README.md` for host context
- `stacks/daedalus/komodo/README.md` for one routed app
- `stacks/daedalus/forgejo/README.md` for another routed app
