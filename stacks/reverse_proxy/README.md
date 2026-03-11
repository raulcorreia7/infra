# Reverse Proxy Stack

This stack runs a single public-facing Caddy instance for edge HTTP and HTTPS
traffic. Caddy owns ports `80` and `443`, terminates TLS, and forwards requests
to internal services that already share the external `${EDGE_NETWORK}` Docker
network.

## Files

- `compose.yaml` starts the Caddy container.
- `config/Caddyfile.example` is the tracked template you copy and edit locally.
- `data/` stores Caddy runtime state, including ACME account data and issued certificates.

## Setup

1. Copy the example file: `cp config/Caddyfile.example config/Caddyfile`
2. Review `config/Caddyfile`. The committed default already targets
   `cerberus.raulcorreia.dev`.
3. If you reuse this stack for another host later, replace that hostname in the
   copied file.
4. Make sure the `${EDGE_NETWORK}` external Docker network already exists.
5. Start the stack: `docker compose up -d`

## Routing Model

The example configuration uses one hostname and two routes on
`cerberus.raulcorreia.dev`:

- Requests for `/admin*` go to `headplane:3000`.
- All other requests go to `headscale:8080`.

The `/admin` prefix is preserved when proxying to Headplane, so Headplane must be prepared to serve that path as-is.

## Storage Ownership

Caddy owns both public TLS listeners and the certificate material stored in
`stacks/reverse_proxy/data`. The container also persists `/config` in the
`caddy_config` Docker volume for Caddy's saved configuration state.

## Extending Later

To add more routes later, keep the same copy-edit workflow:

1. Edit `config/Caddyfile`.
2. Add more `handle` blocks or additional site blocks for new services.
3. Reload or recreate the container with `docker compose up -d`.

Keep the public hostname and path rules together in the Caddyfile so the edge routing logic stays easy to read.
