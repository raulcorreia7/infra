# Athena

`athena` is the Proxmox host.

## Table Of Contents

- [Role](#role)
- [Current Shape](#current-shape)
- [VM Plan](#vm-plan)
- [Durable Rule](#durable-rule)
- [Related Docs](#related-docs)

## Role

It is not the main Docker Compose app runtime. Its current role is:

- Proxmox hypervisor
- Tailscale subnet-router support
- VM and LXC provisioning notes

## Current Shape

- Proxmox host: `athena.home.arpa`
- existing Tailscale role lives in an LXC, not on the host directly
- current subnet route advertised from that LXC: `192.168.100.0/24`
- future Docker app workloads should live on the `daedalus` VM, not directly on `athena`

## VM Plan

Create `daedalus` with the Proxmox VE Docker VM helper in Advanced mode.

Recommended size:

- `4` CPU
- `10240` MiB RAM
- `64G` disk

Upstream helper flow:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/docker-vm.sh)"
```

Then install Komodo inside the VM:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/komodo.sh)"
```

## Durable Rule

Keep `athena` for hypervisor concerns.

Put Compose-managed services on `daedalus` so the repo can keep using the
generic `bin/` workflow unchanged.

For remote access, the Tailscale LXC on `athena` is the bridge between the
tailnet and the homelab LAN.

## Related Docs

- `docs/homelab.md` for network context
- `docs/getting-started.md` for setup workflow
- `stacks/daedalus/README.md` for the Docker VM role
