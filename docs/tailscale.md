# Tailnet Access

Use this guide to join the Headscale tailnet on Cerberus, run common admin
tasks, and migrate clients to `vpn.raulcorreia.dev`.

## Defaults

- login server: `https://vpn.raulcorreia.dev`
- compatibility alias: `https://tailscale.cerberus.raulcorreia.dev`
- admin UI: `https://vpn.raulcorreia.dev/admin`
- private homelab DNS: `*.home.arpa`

## Quick Start

Create a reusable pre-auth key on Cerberus:

```bash
cd ~/infra/stacks/cerberus/headscale_vpn
docker compose exec headscale \
  headscale preauthkeys create --user <user> --reusable --expiration 24h
```

Join from the client:

```bash
sudo tailscale up \
  --login-server https://vpn.raulcorreia.dev \
  --authkey <tskey>
```

Linux clients that should reach the homelab subnet also need:

```bash
sudo tailscale set --accept-routes
```

## Migrate Existing Clients

The cleanest migration path is to create a fresh reusable pre-auth key and use
it during re-auth.

On Cerberus:

```bash
cd ~/infra/stacks/cerberus/headscale_vpn
docker compose exec headscale \
  headscale preauthkeys create --user <user> --reusable --expiration 24h
```

On the client:

```bash
sudo tailscale up \
  --force-reauth \
  --login-server https://vpn.raulcorreia.dev \
  --hostname "$(tailscale status --json | jq -r '.Self.HostName')" \
  --authkey <tskey>
```

Linux client with subnet routes enabled:

```bash
sudo tailscale up \
  --force-reauth \
  --login-server https://vpn.raulcorreia.dev \
  --hostname "$(tailscale status --json | jq -r '.Self.HostName')" \
  --authkey <tskey> \
  --accept-routes
```

Notes:

- changing `--login-server` requires `--force-reauth`
- many clients require `sudo` for `tailscale up`
- if `jq` is unavailable, use the hostname Tailscale prints in the error message
- to avoid needing `sudo` for future commands on that machine, run `sudo tailscale set --operator "$USER"` once

After migration, verify:

- the client appears in `https://vpn.raulcorreia.dev/admin`
- `tailscale status` shows the new login server
- `*.home.arpa` names still resolve where expected

## Admin Tasks

Run these on Cerberus:

```bash
cd ~/infra/stacks/cerberus/headscale_vpn
```

Create a user:

```bash
docker compose exec headscale headscale users create <user>
```

List users:

```bash
docker compose exec headscale headscale users list
```

Create a reusable pre-auth key:

```bash
docker compose exec headscale \
  headscale preauthkeys create --user <user> --reusable --expiration 24h
```

List nodes:

```bash
docker compose exec headscale headscale nodes list
```

Register a node after interactive login:

```bash
docker compose exec headscale \
  headscale nodes register --user <user> --key <machine-key>
```

Create an API key:

```bash
docker compose exec headscale headscale apikeys create --expiration 90d
```

List API keys:

```bash
docker compose exec headscale headscale apikeys list
```

Expire an API key:

```bash
docker compose exec headscale headscale apikeys expire --prefix <prefix>
```

Existing API keys are usually not recoverable in plain text after creation. If
you lost the value, create a new key instead.

## Related Docs

- `stacks/cerberus/headscale_vpn/README.md` for stack details
- `stacks/cerberus/reverse_proxy/README.md` for public routing
- `docs/homelab.md` for subnet and DNS context
