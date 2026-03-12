# Forgejo Runners

Dedicated Actions runner stack for Forgejo.

## Purpose

- keep runners separate from the Forgejo app stack
- make the CI layer portable and still Compose-first
- keep Komodo optional

## Recommended Model

- one runner container
- one `docker:dind` sidecar
- persistent runner state
- persistent DIND cache
- start with runner capacity `1`

## Phase 4 Tasks

- add real `compose.yaml`
- add runner registration flow and config
- document labels and trust boundaries
- validate Docker-based workflows

## Not Built Yet

This folder is a skeleton only. There is no `compose.yaml` yet.
