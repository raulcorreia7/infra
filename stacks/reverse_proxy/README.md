# Reverse Proxy Stack

This stack runs a single public-facing Caddy instance for edge HTTP and HTTPS
traffic. Caddy owns ports `80` and `443`, terminates TLS, and forwards requests
to internal services that already share the external `${EDGE_NETWORK}` Docker
network.

## Files

- `compose.yaml` starts the Caddy container.
- `config/Caddyfile.template` is the tracked template rendered during setup.
- `data/` stores Caddy runtime state, including ACME account data and issued certificates.

## Setup

1. Run `bash bin/setup.sh <host>` to render `config/Caddyfile` from the host env.
2. Review `config/Caddyfile`.
3. Make sure the `${EDGE_NETWORK}` external Docker network already exists.
4. Start the stack: `docker compose up -d`

## Routing Model

The rendered configuration uses one hostname from `PUBLIC_FQDN` and two routes:

- Requests for `/admin*` go to `headplane:3000`.
- All other requests go to `headscale:8080`.

The `/admin` prefix is preserved when proxying to Headplane, so Headplane must be prepared to serve that path as-is.

## Default rule

Treat Caddy as the public entrypoint. Application stacks should stay internal by
default and rely on the reverse proxy for access unless you are doing temporary
local testing.

## Storage Ownership

Caddy owns both public TLS listeners and the certificate material stored in
`stacks/reverse_proxy/data`. The container also persists `/config` in the
`caddy_config` Docker volume for Caddy's saved configuration state.

## Extending Later

To add more routes later, keep the same render-and-review workflow:

1. Edit `config/Caddyfile`.
2. Add more `handle` blocks or additional site blocks for new services.
3. Reload or recreate the container with `docker compose up -d`.

Keep the public hostname and path rules together in the Caddyfile so the edge routing logic stays easy to read.
