# Headscale VPN

This stack runs a private Headscale control plane with the Headplane web UI.
Both containers join an existing edge network and expect Caddy to terminate TLS
and route traffic on the hostname from `hosts/<host>/.env`, so the compose
stack does not publish any public ports.

Rule of thumb: keep these services internal and access them through the reverse
proxy stack. Direct port publishing is only a temporary testing escape hatch.

## What is included

- `compose.yaml` for `headscale` and `headplane`
- Host-driven config templates rendered during setup
- `post.sh` to seed the current default users after the stack starts
- Empty data directories for persistent application state
- A local `.gitignore` for runtime data and real config files
- Stable container names so `docker exec headscale ...` and `docker exec headplane ...` work as expected on the host

## Files rendered during setup

`bash bin/setup.sh <host>` renders the missing local config files from the host
env:

```bash
bash bin/setup.sh cerberus
```

This stack uses these host env values when rendering:

- `PUBLIC_FQDN`
- `TAILNET_DOMAIN`
- `HEADPLANE_COOKIE_SECRET` (optional; generated on first render if unset)

If you later move Headscale policy storage to a file, setup also copies the
starter file below when it is missing:

```bash
cp stacks/headscale_vpn/config/policy.example.yaml stacks/headscale_vpn/config/policy.yaml
```

Important:

- The tracked templates are `config.template.yaml` files.
- The rendered local files are plain YAML files mounted into the containers.
- Re-run `setup` safely; it will not overwrite existing local config files.
- Keep Headplane `server.base_url` as a full external URL without `/admin`.

## Required environment

Create or export `EDGE_NETWORK` before starting the stack. It must point to an
already existing Docker network used by your reverse proxy.

Example:

```bash
export EDGE_NETWORK=edge
docker compose -f stacks/headscale_vpn/compose.yaml up -d
```

## Reverse proxy notes

- Route `/admin*` to `headplane:3000` on the shared edge network.
- Route every other request on your `PUBLIC_FQDN` to `headscale:8080`.
- TLS termination should happen at the reverse proxy, not inside this stack.

## Current defaults

- MagicDNS is enabled.
- The tailnet base domain comes from `TAILNET_DOMAIN`.
- The home domain is `home.arpa`.
- Global resolvers are `9.9.9.9`, `1.1.1.1`, and `1.0.0.1`.
- Split DNS sends `home.arpa` to `192.168.100.1`.
- Search domains include `home.arpa`.
- `post.sh` seeds the users `gil` and `raul` after `bash bin/up.sh cerberus`.

## Generate a Headscale API key

Use this for Headplane API-key login or other administrative tooling:

```bash
docker compose -f stacks/headscale_vpn/compose.yaml exec headscale \
  headscale apikeys create --expiration 90d
```

## Basic enrollment flow

Create a user:

```bash
docker compose -f stacks/headscale_vpn/compose.yaml exec headscale \
  headscale users create alice
```

Create a reusable pre-auth key:

```bash
docker compose -f stacks/headscale_vpn/compose.yaml exec headscale \
  headscale preauthkeys create --user alice --reusable --expiration 24h
```

Enroll a client with that key:

```bash
tailscale up --login-server https://<PUBLIC_FQDN> --authkey tskey-...
```

Interactive enrollment is also possible:

```bash
tailscale up --login-server https://<PUBLIC_FQDN>
docker compose -f stacks/headscale_vpn/compose.yaml exec headscale \
  headscale nodes register --user alice --key <machine-key>
```

## Data locations

- Headscale data lives in `stacks/headscale_vpn/data/headscale`
- Headplane data lives in `stacks/headscale_vpn/data/headplane`

These directories hold persistent runtime state and are ignored by the stack's
local `.gitignore`.

## Policy placeholder

`stacks/headscale_vpn/config/policy.example.yaml` is a small starter file for
future ACL and tag work. The example Headscale config keeps policy storage in
database mode by default so you can bring the stack up first and switch to a
file-backed policy later if you want it.
