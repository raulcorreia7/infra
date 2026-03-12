# Media Server

Playback stack for Jellyfin.

## Purpose

- keep playback separate from download and indexer churn
- expose the UI only through `reverse_proxy`

## Planned Hostname

- `jellyfin.home.arpa`

## Storage Rule

- bulk media should stay on `chronos`
- `daedalus` should only hold config, cache, and metadata

## Phase 4 Tasks

- add real `compose.yaml`
- define media, config, cache, and transcode paths
- decide hardware acceleration strategy

## Not Built Yet

This folder is a skeleton only. There is no `compose.yaml` yet.
