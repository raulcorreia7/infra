# Immich

Photo stack for `daedalus`.

## Purpose

- keep the photo stack isolated from media automation and Jellyfin
- expose the UI only through `reverse_proxy`

## Likely Services

- Immich server
- machine learning
- PostgreSQL
- Redis

## Storage Rule

- originals should live on durable mounted storage
- metadata, cache, and database state stay on `daedalus`

## Phase 4 Tasks

- add real `compose.yaml`
- define photo library and upload paths
- define DB and Redis persistence

## Not Built Yet

This folder is a skeleton only. There is no `compose.yaml` yet.
