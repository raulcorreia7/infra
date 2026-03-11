# Homelab Topology

This repo models one active public VPS and a local homelab behind pfSense.

Current roles:

- `cerberus`: active VPS and public entrypoint
- `raulcorreia.dev`: public domain managed in Cloudflare
- `chronos`: NAS running TrueNAS SCALE
- `athena`: Proxmox host for containers and future internal workloads
- `talos`: desktop
- laptops and phone: user devices and Tailnet clients

## L0 Overview

```text
        +------------------+
        |     Internet     |
        +------------------+
                  |
                  v
        +------------------+
        |    Cloudflare    |
        |  raulcorreia.dev |
        +------------------+
                  |
                  v
        +------------------------------+
        |            cerberus          |
        | VPS / public entrypoint      |
        | cerberus.raulcorreia.dev     |
        +------------------------------+
                  |
        +---------+---------+
        |                   |
        v                   v
+----------------+  +----------------------+
| reverse_proxy  |  |    headscale_vpn     |
| Caddy          |  | Headscale+Headplane  |
+----------------+  +----------------------+
        |                   |
        +---------+---------+
                  |
                  v
        +--------------------------+
        | Tailscale / admin clients|
        | laptops, phone, desktop  |
        +--------------------------+


        +------------------------------------------------------+
        |                    homelab LAN                       |
        +------------------------------------------------------+
                  |
                  v
        +------------------+
        |  pfSense router   |
        +------------------+
          |    |      |    |-------------------------------+
          |    |      |                                    |
          v    v      v                                    v
   +----------+ +---------+ +---------+        +----------------------+
   | access   | | chronos | | athena  |        | clients              |
   | point    | | TrueNAS | | Proxmox |        | talos, laptops, phone|
   +----------+ +---------+ +---------+        +----------------------+
```

## L1 Cerberus Runtime Layout

```text
 +----------------------------------------------------------+
 |                       cerberus VPS                        |
 +----------------------------------------------------------+
 | public ports                                              |
 |   80/tcp  -> Caddy                                        |
 |   443/tcp -> Caddy                                        |
 +----------------------------------------------------------+
 | Docker external network: edge                             |
 |                                                          |
 |   +----------------+     +----------------------------+   |
 |   | caddy          |     | headscale                  |   |
 |   | TLS owner      |     | control plane API          |   |
 |   | /admin -> hp   |     | sqlite + noise key state   |   |
 |   | /* -> hs       |     +----------------------------+   |
 |   |                |                                      |
 |   |                |     +----------------------------+   |
 |   |                |     | headplane                  |   |
 |   |                |     | admin UI on /admin         |   |
 |   |                |     | talks to headscale + Docker|   |
 |   +----------------+     +----------------------------+   |
 +----------------------------------------------------------+
 | local repo state                                          |
 |   hosts/cerberus/.env                                     |
 |   rendered config files under stacks/*/config             |
 |   runtime state under stacks/*/data                       |
 +----------------------------------------------------------+
```

## Access Rule

```text
Public traffic -> Caddy -> internal services
```

Rule of thumb:

- In production, do not expose Headscale or Headplane directly.
- Use the reverse proxy stack as the public entrypoint.
- Only enable direct app ports as a short-lived testing shortcut.

## L1 Homelab Layout

```text
 +-------------+      +----------------+      +----------------------+
 |     ISP     | ---> | pfSense router | ---> | access point / Wi-Fi |
 +-------------+      +----------------+      +----------------------+
                              |
         +--------------------+--------------------+------------------+
         |                    |                    |                  |
         v                    v                    v                  v
  +-------------+      +-------------+      +-------------+   +-------------+
  |   chronos   |      |   athena    |      |    talos    |   | mobile /    |
  | TrueNAS     |      | Proxmox     |      | desktop     |   | laptop       |
  +-------------+      +-------------+      +-------------+   +-------------+
```

## Request Flow

### Headscale API / client traffic

```text
Tailscale client
  -> https://cerberus.raulcorreia.dev
  -> Caddy
  -> headscale:8080
  -> Headscale state in sqlite
```

### Headplane admin traffic

```text
Browser
  -> https://cerberus.raulcorreia.dev/admin
  -> Caddy
  -> headplane:3000
  -> Headplane talks to headscale:8080 and Docker socket
```

## DNS Defaults

The rendered Headscale config currently applies these defaults:

```text
MagicDNS: enabled
Tailnet domain: tailnet.cerberus.raulcorreia.dev
Global resolvers: 9.9.9.9, 1.1.1.1, 1.0.0.1
Split DNS: home.arpa -> 192.168.100.1
Search domains: home.arpa
```

These values come from the tracked template and host env driven setup flow.

## Host Configuration Model

```text
hosts/<host>/.env        -> source of truth for host-specific values
hosts/<host>/stacks.txt  -> enabled stack list for that host
stacks/*/*.template*     -> rendered once by bin/setup.sh when missing
stacks/*/*.example*      -> copied once for static starter files when missing
```

## Proxmox Notes

The current Proxmox plan centers on `athena` and assumes:

- Proxmox VE community Alpine LXC bootstrap
- Tailscale added to that LXC afterward

References:

- `https://community-scripts.org/scripts/alpine`
- `https://community-scripts.org/scripts/add-tailscale-lxc`

## Evolution Path

Likely next expansions:

- enable stacks for `chronos` and `athena`
- add more public services behind Caddy on `cerberus`
- use `athena` for internal services or network-adjacent workloads
- keep the same pattern: host env -> rendered config -> Compose lifecycle
