# Getting Started

## Flow

```text
host env -> setup -> rendered local config -> up -> verify-runtime
                                     \-> teardown
```

## Bring Up A Host

1. Copy `stacks/<host>/.env.example` to `stacks/<host>/.env`.
2. Fill in the host values.
3. Add or remove stack folders under `stacks/<host>/`.
4. Run `bash bin/setup.sh <host>`.
5. Run `bash bin/validate-config.sh <host>`.
6. Review the rendered local config files.
7. Run `bash bin/up.sh <host>`.
8. Run `bash bin/verify-runtime.sh <host>` after startup.
9. Run `bash bin/teardown.sh <host>` when you want to remove stack resources.
10. Run `bash bin/teardown.sh --remove <host>` for a full local reset.

## Host Model

- `stacks/<host>/.env` is the source of truth for host-specific values.
- `stacks/<host>/<stack>/compose.yaml` marks a stack as enabled for that host.
- `stacks/<host>/<stack>/*.template*` files render once when missing.
- `stacks/<host>/<stack>/*.example*` files copy once when missing.

## Rendering Rules

- Existing local files are never overwritten.
- `HEADPLANE_COOKIE_SECRET` can be set in `stacks/<host>/.env`.
- If that secret is unset, setup generates one on first render.
- `HOME_DOMAIN` and `HOME_DNS_RESOLVER` drive the Tailnet split-DNS defaults.

## Current Active Host

`cerberus` uses:

- `reverse_proxy`
- `headscale_vpn`

The domain defaults already live in `stacks/cerberus/.env.example`.

## Add A Host

1. Create `stacks/<host>/`.
2. Add `stacks/<host>/.env.example`.
3. Add one folder per enabled stack under `stacks/<host>/`.
4. Copy the example env to a local `.env`.
5. Run `bash bin/setup.sh <host>`.

## Athena Notes

`athena` is the current Proxmox placeholder and assumes an Alpine LXC plus
Tailscale.

```bash
var_cpu="2" var_disk="2" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/alpine.sh)"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh)"
```

References:

- `https://community-scripts.org/scripts/alpine`
- `https://community-scripts.org/scripts/add-tailscale-lxc`
