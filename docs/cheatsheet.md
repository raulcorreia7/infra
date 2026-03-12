# Cheatsheet

Shortest useful commands for the current repo.

## Working Styles

- local: run the lifecycle commands directly from your local repo
- remote deploy: use `./bin/deploy.sh ...`
- cloned remote repo: `git pull`, then run the same lifecycle commands there

## Bring Up Cerberus

```bash
cp stacks/cerberus/.env.example stacks/cerberus/.env
./bin/doctor.sh cerberus
./bin/deploy.sh cerberus
```

## Deploy Cerberus

```bash
./bin/deploy.sh cerberus
```

## Remote Deploy

```bash
./bin/helpers/install-ssh-key.sh root@cerberus.raulcorreia.dev
./bin/deploy.sh --remote root@cerberus.raulcorreia.dev cerberus
```

## Run On The Remote Host

```bash
git pull
./bin/deploy.sh cerberus
```

## Manual Lifecycle

```bash
./bin/setup.sh --refresh cerberus
./bin/validate-config.sh cerberus
./bin/up.sh cerberus
./bin/health.sh cerberus
```

## DNS

```bash
./bin/helpers/install-dnscontrol.sh
./bin/dnscontrol preview
./bin/dnscontrol push
```

## Tailnet

```bash
cd stacks/cerberus/headscale_vpn
docker compose exec headscale \
  headscale preauthkeys create --user <user> --reusable --expiration 24h
```

```bash
sudo tailscale up \
  --force-reauth \
  --login-server https://vpn.raulcorreia.dev \
  --hostname "$(tailscale status --json | jq -r '.Self.HostName')" \
  --authkey <tskey>
```

## Local Stack Debugging

```bash
cp stacks/daedalus/.env.example stacks/daedalus/.env
./bin/setup.sh daedalus
cd stacks/daedalus/komodo
docker compose -f compose.yaml -f compose.local.yaml up -d
docker compose -f compose.yaml -f compose.local.yaml logs -f
```

## Stop And Cleanup

```bash
./bin/logs.sh cerberus
./bin/down.sh cerberus
./bin/teardown.sh cerberus
./bin/teardown.sh --remove cerberus
```
