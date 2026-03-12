# Homepage

Internal dashboard for `daedalus`.

## Purpose

- provide a human dashboard for homelab services
- stay internal by default
- expose the UI only through `reverse_proxy`

## Planned Hostname

- `homepage.home.arpa`

## Likely Image

- `ghcr.io/gethomepage/homepage:latest`

## Phase 4 Tasks

- add real `compose.yaml`
- add config files such as `settings.yaml`, `services.yaml`, and `widgets.yaml`
- set `HOMEPAGE_ALLOWED_HOSTS`
- add links/widgets for Komodo, Forgejo, and later stacks
- decide whether Docker socket integration is worth enabling

## Not Built Yet

This folder is a skeleton only. There is no `compose.yaml` yet.
