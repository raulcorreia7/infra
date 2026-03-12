# Docs

Use this page as the operator map for the repo.

## Start Here

- repo overview: `README.md`
- first bring-up: `docs/getting-started.md`
- shortest commands: `docs/cheatsheet.md`
- topology and routing: `docs/homelab.md`

## Common Jobs

| Job | Read | Run |
| --- | --- | --- |
| Bring up a host | `docs/getting-started.md` | `doctor -> setup -> validate-config -> up -> health` |
| Refresh rendered config | `docs/getting-started.md` | `refresh-config -> validate-config -> up -> health` |
| Deploy to a remote host | `docs/getting-started.md` | `install-ssh-key -> sync -> deploy` |
| Manage Cloudflare DNS | `dns/README.md` | `install-dnscontrol -> dnscontrol preview -> dnscontrol push` |
| Join or migrate a tailnet client | `docs/tailscale.md` | create pre-auth key -> `tailscale up` |

## Core Docs

| File | Purpose |
| --- | --- |
| `README.md` | Repo overview and command groups |
| `docs/cheatsheet.md` | Shortest useful commands |
| `docs/getting-started.md` | Canonical host lifecycle and remote deploy workflow |
| `docs/homelab.md` | Topology, routing, and DNS context |
| `docs/tailscale.md` | Headscale quick start, admin tasks, and client migration |
| `dns/README.md` | DNSControl setup and Cloudflare token guidance |
| `dns/dnsconfig.js` | Cloudflare DNS source of truth |

## Host And Stack Docs

| File | Purpose |
| --- | --- |
| `stacks/athena/README.md` | Athena hypervisor notes |
| `stacks/daedalus/README.md` | Daedalus host notes and planned stack inventory |
| `stacks/cerberus/reverse_proxy/README.md` | Public Caddy edge on Cerberus |
| `stacks/cerberus/headscale_vpn/README.md` | Headscale and Headplane stack details |
| `stacks/daedalus/reverse_proxy/README.md` | Internal Caddy ingress on Daedalus |
| `stacks/daedalus/komodo/README.md` | Komodo operator stack |
| `stacks/daedalus/forgejo/README.md` | Forgejo app stack |

## Doc Rules

- keep one canonical workflow doc for generic lifecycle steps
- keep stack docs focused on what is specific to that stack
- link to related docs instead of repeating the same workflow everywhere
- prefer short, operational, high-signal prose
