# Cheatsheet

Shortest useful commands for the current repo.

## Local Debug

Bring up one stack locally from the repo:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus

cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
./stack-health.sh
```

Useful local stack commands:

```bash
docker compose -f compose.yaml -f compose.local.yaml ps
docker compose -f compose.yaml -f compose.local.yaml logs -f
docker compose -f compose.yaml -f compose.local.yaml down
```

## Daedalus Bring-Up

Bring up the full app host workflow:

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
./bin/validate-config.sh daedalus
./bin/up.sh daedalus
./bin/health.sh daedalus
```

## Cerberus Bring-Up

```bash
./bin/doctor.sh
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/setup.sh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

## Athena Notes

`athena` is the Proxmox host.

Use it to create and host `daedalus`, then run the generic Compose workflow on
`daedalus`, not on `athena` itself.

## Stop And Cleanup

Stop a host:

```bash
./bin/down.sh daedalus
```

Remove runtime resources:

```bash
./bin/teardown.sh daedalus
```

Full local reset:

```bash
./bin/teardown.sh --remove daedalus
```
