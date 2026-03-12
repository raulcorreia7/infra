# Headscale VPN

This stack runs a private Headscale control plane with the Headplane web UI.
Both containers join an existing edge network and expect Caddy to terminate TLS
and route traffic on the hostname from `stacks/<host>/.env`, so the compose
stack does not publish any public ports.

Default rule: keep these services internal and access them through the reverse
proxy stack. Direct port publishing is only a temporary testing escape hatch.

## Table Of Contents

- [What Is Included](#what-is-included)
- [Files Rendered During Setup](#files-rendered-during-setup)
- [Required Environment](#required-environment)
- [Reverse Proxy Notes](#reverse-proxy-notes)
- [Current Defaults](#current-defaults)
- [Admin Tasks](#admin-tasks)
- [Data Locations](#data-locations)
- [Policy Placeholder](#policy-placeholder)
- [Related Docs](#related-docs)

## What Is Included

- `compose.yaml` for `headscale` and `headplane`
- host-driven config templates rendered during setup
- `stack-up.sh` for stack-local startup tasks
- `seed-users.sh` to optionally create local Headscale users after the stack starts
- empty data directories for persistent application state
- a local `.gitignore` for runtime data and real config files
- stable container names so `docker exec headscale ...` and `docker exec headplane ...` work as expected on the host

## Files Rendered During Setup

`./bin/setup.sh <host>` renders the missing local config files from the host
env:

```bash
./bin/setup.sh cerberus
```

This stack uses these host env values when rendering:

- `PUBLIC_FQDN`
- `TAILNET_DOMAIN`
- `HOME_DOMAIN`
- `HOME_DNS_RESOLVER`
- `HEADSCALE_SEED_USERS` optional comma-separated user list
- `HEADPLANE_COOKIE_SECRET` optional and generated on first render if unset

If you later move Headscale policy storage to a file, setup also copies the
starter file below when it is missing:

```bash
cp stacks/<host>/headscale_vpn/config/policy.example.yaml \
  stacks/<host>/headscale_vpn/config/policy.yaml
```

Important:

- tracked templates are `config.template.yaml` files
- rendered local files are plain YAML files mounted into the containers
- re-running setup is safe and does not overwrite existing local config files
- keep Headplane `server.base_url` as the full external host URL

## Required Environment

Set `EDGE_NETWORK` in `stacks/<host>/.env`. It must point to the shared Docker
network used by the reverse proxy stack.

Example:

```bash
./bin/setup.sh <host>
./bin/up.sh <host>
```

For local debugging:

```bash
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/setup.sh cerberus
cd stacks/cerberus/headscale_vpn
docker compose -f compose.yaml -f compose.local.yaml up -d
```

## Reverse Proxy Notes

- Route `/admin*` to `headplane:3000` on the shared edge network
- Route every other request on your `PUBLIC_FQDN` to `headscale:8080`
- TLS termination should happen at the reverse proxy, not inside this stack

## Current Defaults

- MagicDNS is enabled
- The public control-plane hostname comes from `PUBLIC_FQDN`
- The tailnet base domain comes from `TAILNET_DOMAIN`
- The home domain comes from `HOME_DOMAIN`
- Global resolvers are `9.9.9.9`, `1.1.1.1`, and `1.0.0.1`
- Split DNS sends `HOME_DOMAIN` to `HOME_DNS_RESOLVER`
- Search domains include `HOME_DOMAIN`
- `seed-users.sh` only creates users listed in `HEADSCALE_SEED_USERS`

Recommended current value:

- `PUBLIC_FQDN=tailscale.cerberus.raulcorreia.dev`

Remote clients on public networks should use `PUBLIC_FQDN` for the Headscale
control plane, then use the advertised subnet route plus `home.arpa` DNS to
reach private homelab machines.

Client note:

- Windows, macOS, iOS, Android, and tvOS accept subnet routes by default
- Linux clients need `tailscale set --accept-routes`
- `home.arpa` hostnames only work if your private DNS server contains those records

## Admin Tasks

Generate a Headscale API key:

```bash
docker compose -f stacks/<host>/headscale_vpn/compose.yaml exec headscale \
  headscale apikeys create --expiration 90d
```

Create a user:

```bash
docker compose -f stacks/<host>/headscale_vpn/compose.yaml exec headscale \
  headscale users create alice
```

Create a reusable pre-auth key:

```bash
docker compose -f stacks/<host>/headscale_vpn/compose.yaml exec headscale \
  headscale preauthkeys create --user alice --reusable --expiration 24h
```

Enroll a client with that key:

```bash
tailscale up --login-server https://<PUBLIC_FQDN> --authkey tskey-...
```

Interactive enrollment is also possible:

```bash
tailscale up --login-server https://<PUBLIC_FQDN>
docker compose -f stacks/<host>/headscale_vpn/compose.yaml exec headscale \
  headscale nodes register --user alice --key <machine-key>
```

## Data Locations

- Headscale data lives in `stacks/<host>/headscale_vpn/data/headscale`
- Headplane data lives in `stacks/<host>/headscale_vpn/data/headplane`

These directories hold persistent runtime state and are ignored by the stack's
local `.gitignore`.

## Policy Placeholder

`stacks/<host>/headscale_vpn/config/policy.example.yaml` is a small starter file
for future ACL and tag work. The example Headscale config keeps policy storage
in database mode by default so you can bring the stack up first and switch to a
file-backed policy later if you want it.

## Related Docs

- `docs/homelab.md` for tailnet and network context
- `docs/getting-started.md` for setup workflow
- `stacks/cerberus/reverse_proxy/README.md` for public routing
