# Reverse Proxy Stack

This stack runs a single public-facing Caddy instance for edge HTTP and HTTPS
traffic. Caddy owns ports `80` and `443`, terminates TLS, and forwards requests
to internal services that already share the external `${EDGE_NETWORK}` Docker
network.

## Table Of Contents

- [Files](#files)
- [Setup](#setup)
- [Routing Model](#routing-model)
- [Storage Ownership](#storage-ownership)
- [Extending Later](#extending-later)
- [Related Docs](#related-docs)

## Files

- `compose.yaml` starts the Caddy container
- `config/Caddyfile.template` is the tracked template rendered during setup
- `data/caddy/` stores ACME account data and issued certificates
- `data/config/` stores Caddy's persisted config state

## Setup

1. Run `./bin/setup.sh <host>` to render `config/Caddyfile` from the host env.
2. Review `config/Caddyfile`.
3. Start the host with `./bin/up.sh <host>`.

## Routing Model

The rendered configuration uses one hostname from `PUBLIC_FQDN` and two routes:

- Requests for `/admin*` go to `headplane:3000`
- All other requests go to `headscale:8080`

Recommended current value:

- `PUBLIC_FQDN=tailscale.cerberus.raulcorreia.dev`

This keeps the public Headscale control plane on a dedicated public subdomain
instead of mixing it into the main Cerberus hostname.

## Storage Ownership

Caddy owns both public TLS listeners and the certificate material stored in
`stacks/<host>/reverse_proxy/data/caddy`. Caddy's saved config state lives in
`stacks/<host>/reverse_proxy/data/config`.

This stack uses bind mounts for both paths so state stays visible, portable,
and easy to migrate.

## Extending Later

To add more routes later, keep the same render-and-review workflow:

1. Edit `config/Caddyfile`.
2. Add more `handle` blocks or additional site blocks for new services.
3. Re-run `./bin/up.sh <host>` or use `./bin/logs.sh <host> reverse_proxy` while iterating.

Keep the public hostname and path rules together in the Caddyfile so the edge
routing logic stays easy to read.

Cerberus can also proxy selected homelab services later. For example,
`jellyfin.raulcorreia.dev` can point to a private service on `daedalus` or
another internal host as long as Cerberus has a reachable path to that origin.

Cloudflare should only hold the public `*.raulcorreia.dev` records that point to
Cerberus. Private `*.home.arpa` access stays on the tailnet and homelab DNS
path.

For public hostnames like `tailscale.cerberus.raulcorreia.dev` or future
`jellyfin.raulcorreia.dev`, add Cloudflare DNS records that point to the
Cerberus public IP.

## Related Docs

- `docs/homelab.md` for edge topology
- `docs/getting-started.md` for host bring-up flow
- `stacks/cerberus/headscale_vpn/README.md` for the current backend stack
