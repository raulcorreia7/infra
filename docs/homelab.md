# Homelab

Small, public edge on the VPS. Everything else stays inside the homelab or
behind Caddy unless there is a short-lived testing reason not to.

## Big Picture

```text
                          .------------------------.
                          |        Internet        |
                          '-----------+------------'
                                      |
                          .-----------v------------.
                          |      Cloudflare DNS    |
                          |     raulcorreia.dev    |
                          '-----------+------------'
                                      |
                       cerberus.raulcorreia.dev / edge
                                      |
               .----------------------v-----------------------.
               |                  cerberus                    |
               |                    VPS                       |
               |                                             |
               |  .----------------.    .-----------------.  |
               |  | Caddy          |--->| Headscale       |  |
               |  | reverse_proxy  |    | control plane   |  |
               |  '--------+-------'    '---------+-------'  |
               |           |                        ^         |
               |           '-------> Headplane ----'         |
               '----------------------+----------------------'
                                      |
                            Tailnet / admin clients


 .------------------------.   .------------------------.   .----------------------.
 | ISP router / upstream  |-->| hermes / pfSense       |-->| access point / LAN   |
 | 192.168.178.1/24       |   | 192.168.100.1/24       |   '----------+-----------'
 '------------------------'   '-----------+------------'              |
                                                |                     |
              .---------------------------------+---------------------+----------------.
              |                                 |                     |                |
      .-------v-------.                 .-------v-------.     .-------v-------. .------v------.
      | chronos       |                 | athena        |     | talos         | | laptops /   |
      | TrueNAS SCALE |                 | Proxmox       |     | desktop       | | phone       |
      '---------------'                 '---------------'     '---------------' '-------------'
```

## Default Rule

```text
public traffic -> Caddy -> internal service
```

- `cerberus` is the public edge.
- `reverse_proxy` is the normal entrypoint.
- `headscale` and `headplane` stay internal by default.
- Direct ports are a testing shortcut, not the normal shape.

## Cerberus

```text
80/443
  -> Caddy
     -> /admin  -> Headplane
     -> /       -> Headscale

Docker network: edge
Repo source of truth: hosts/cerberus/.env
Rendered local config: stacks/*/config/*
Runtime state: stacks/*/data/*
```

## Homelab

```text
ISP
  -> ISP router / upstream  (192.168.178.1/24)
    -> hermes / pfSense     (192.168.100.1/24)
    -> access point
    -> chronos  (TrueNAS SCALE)
    -> athena   (Proxmox / containers)
    -> talos    (desktop)
    -> laptops
    -> phone
```

## Tailnet Defaults

```text
MagicDNS       enabled
Base domain    tailnet.cerberus.raulcorreia.dev
Resolvers      9.9.9.9, 1.1.1.1, 1.0.0.1
Split DNS      home.arpa -> 192.168.100.1
Search domain  home.arpa
```

## Network Notes

```text
Firewall / router   hermes
LAN gateway         192.168.100.1/24
ISP upstream        192.168.178.1/24
Public edge         cerberus
```
