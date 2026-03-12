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
- local debug access can use `http://127.0.0.1:9120` with `compose.local.yaml`

## Local Login

- username comes from `KOMODO_INIT_ADMIN_USERNAME`
- password comes from `KOMODO_INIT_ADMIN_PASSWORD`
- both live in `stacks/daedalus/.env`
- if the password is left as `change-me-*`, `./bin/setup.sh daedalus` generates it on first run

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
