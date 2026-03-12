# Forgejo

This is the first real app stack on `daedalus`.

## Table Of Contents

- [Owns](#owns)
- [Exposure](#exposure)
- [Durable State](#durable-state)
- [Scope Now](#scope-now)
- [Related Docs](#related-docs)

## Owns

- Forgejo
- PostgreSQL
- built-in Forgejo SSH server

## Exposure

- web: `forgejo.home.arpa` through `reverse_proxy`
- Git SSH: `forgejo.home.arpa:2222`
- no direct web port publishing

For local debugging:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/forgejo
docker compose -f compose.yaml -f compose.local.yaml up -d
```

## Durable State

- `data/forgejo/` -> repos, attachments, indexes, app state
- `data/postgres/` -> database state
- `config/app.ini` -> rendered local config

## Scope Now

- web UI
- repository hosting
- Git over SSH

Deferred:

- runners
- registry
- mail / SSO
- broader platform integrations

## Related Docs

- `stacks/daedalus/README.md` for host role
- `stacks/daedalus/reverse_proxy/README.md` for access path
- `stacks/daedalus/README.md` for planned runner separation
