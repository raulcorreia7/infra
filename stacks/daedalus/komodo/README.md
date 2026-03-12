# Komodo

Komodo is the operator layer for `daedalus`.

Use it to deploy and inspect Compose stacks, but keep the repo as the durable
source of truth.

## Table Of Contents

- [Owns](#owns)
- [Exposure](#exposure)
- [Durable Rule](#durable-rule)
- [Related Docs](#related-docs)

## Owns

- Komodo Core
- Komodo Periphery
- MongoDB for Komodo state

## Exposure

- internal app services only
- web access through `reverse_proxy`
- expected hostname: `komodo.home.arpa`

For local debugging:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
```

## Durable Rule

Stacks should still work with plain `docker compose` if Komodo is removed later.

## Related Docs

- `stacks/daedalus/README.md` for host role
- `stacks/daedalus/reverse_proxy/README.md` for access path
