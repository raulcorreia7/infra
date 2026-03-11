# Getting Started

## Flow

```text
host env -> setup -> rendered local config -> up -> verify
```

## Bring Up A Host

1. Copy `hosts/<host>/.env.example` to `hosts/<host>/.env`.
2. Fill in the host values.
3. Enable stacks in `hosts/<host>/stacks.txt`.
4. Run `bash bin/setup.sh <host>`.
5. Review the rendered local config files.
6. Run `bash bin/up.sh <host>`.
7. Run `bash bin/verify.sh <host>`.

## Host Model

- `hosts/<host>/.env` is the source of truth for host-specific values.
- `hosts/<host>/stacks.txt` is the enabled stack list.
- `stacks/*/*.template*` files render once when missing.
- `stacks/*/*.example*` files copy once when missing.

## Rendering Rules

- Existing local files are never overwritten.
- `HEADPLANE_COOKIE_SECRET` can be set in `hosts/<host>/.env`.
- If that secret is unset, setup generates one on first render.

## Current Active Host

`cerberus` uses:

- `reverse_proxy`
- `headscale_vpn`

The domain defaults already live in `hosts/cerberus/.env.example`.

## Add A Host

1. Create `hosts/<host>/`.
2. Add `hosts/<host>/.env.example`.
3. Add `hosts/<host>/stacks.txt`.
4. Copy the example env to a local `.env`.
5. Run `bash bin/setup.sh <host>`.

## Proxmox Notes

The current Proxmox placeholder assumes an Alpine LXC plus Tailscale.

```bash
var_cpu="2" var_disk="2" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/alpine.sh)"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh)"
```

References:

- `https://community-scripts.org/scripts/alpine`
- `https://community-scripts.org/scripts/add-tailscale-lxc`
