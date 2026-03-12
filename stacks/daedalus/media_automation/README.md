# Media Automation

Download and library automation stack.

## Purpose

- centralize download and automation tools
- keep it separate from Jellyfin playback
- expose the UI only through `reverse_proxy`

## Likely Services

- qBittorrent
- Prowlarr
- Radarr
- Sonarr
- Bazarr
- Recyclarr

## Storage Rule

- long-term media should stay on `chronos`
- only operational state, cache, and working paths should live on `daedalus`

## Phase 4 Tasks

- add real `compose.yaml`
- define shared download and library paths
- decide if any service deserves its own stack

## Not Built Yet

This folder is a skeleton only. There is no `compose.yaml` yet.
