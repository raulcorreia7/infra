# DNS

This directory is the source of truth for the Cloudflare DNS zone for
`raulcorreia.dev`.

## Files

- `dnsconfig.js` is the tracked DNSControl config
- `.env.example` is the local env template for Cloudflare values
- `creds.json.example` is the local DNSControl credentials template

## Local Setup

```bash
./bin/install-dnscontrol.sh
cp dns/.env.example dns/.env
cp dns/creds.json.example dns/creds.json
./bin/doctor.sh
./bin/dnscontrol preview
```

Fill these values in `dns/.env`:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

## Cloudflare Token

Create a scoped API token for the `raulcorreia.dev` zone only.

Required permissions:

- `Zone` -> `Zone` -> `Read`
- `Zone` -> `DNS` -> `Edit`

Notes:

- scope the token to the single `raulcorreia.dev` zone
- `CLOUDFLARE_ACCOUNT_ID` is the Cloudflare account id, not the zone id
- DNSControl uses `preview` to read the live zone and `push` to apply changes

## Notes

- Keep `dns/.env` and `dns/creds.json` local and untracked
- Use `./bin/dnscontrol preview` before `./bin/dnscontrol push`
- The current zone keeps `tailscale.cerberus.raulcorreia.dev` as a temporary
  compatibility alias to `vpn.raulcorreia.dev`
