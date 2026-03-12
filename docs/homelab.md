# Homelab

Small public edge on `cerberus`. Internal services stay behind Caddy by
default.

## Table Of Contents

- [Rule Of Thumb](#rule-of-thumb)
- [Public Edge](#public-edge)
- [Homelab Network](#homelab-network)
- [Where Things Live](#where-things-live)
- [Cerberus Routing](#cerberus-routing)
- [Tailnet Defaults](#tailnet-defaults)
- [Notes](#notes)
- [Related Docs](#related-docs)

## Rule Of Thumb

```text
public traffic -> Caddy -> internal service
```

## Public Edge

```text
                         .----------------------.
                         |       Internet       |
                         '----------+-----------'
                                    |
                         .----------v-----------.
                         |    Cloudflare DNS    |
                         |   raulcorreia.dev    |
                         '----------+-----------'
                                    |
                    cerberus.raulcorreia.dev / 80,443
                                    |
          .-------------------------v-------------------------.
          |                    cerberus VPS                   |
          |                                                   |
          |   .-----------------.      .-------------------.  |
          |   | reverse_proxy   |----->| headscale_vpn     |  |
          |   | Caddy           |      | Headscale         |  |
          |   |                 |----->| Headplane (/admin)|  |
          |   '-----------------'      '-------------------'  |
           '---------------------------------------------------'
                                    |
                             tailnet clients

                         .----------------------.
                         |      daedalus VM     |
                         | Docker + Komodo/apps |
                         '----------------------'
```

## Homelab Network

```text
 .------------------------.     .------------------------.
 | ISP router / upstream  |---->| hermes / pfSense       |
 | 192.168.178.1/24       |     | 192.168.100.1/24       |
 '------------------------'     '-----------+------------'
                                              |
                    .--------+---------------+---------------+---------------+-------------.
                    |        |               |               |               |             |
            .-------v-----. .-v-----------. .-v-----------. .-v---------. .--v----------. .-v----------.
            | chronos     | | athena      | | daedalus    | | talos     | | laptops /   | | access     |
            | TrueNAS     | | Proxmox     | | Docker VM   | | desktop   | | phone       | | point      |
            '-------------' '-------------' '-------------' '-----------' '-------------' '------------'
```

`athena` owns hypervisor concerns. `daedalus` is the Docker VM app host.

## Where Things Live

```text
stacks/cerberus/.env                source of truth for cerberus values

stacks/cerberus/reverse_proxy/compose.yaml   Caddy stack
stacks/cerberus/reverse_proxy/config/        rendered Caddyfile
stacks/cerberus/reverse_proxy/data/          Caddy state

stacks/cerberus/headscale_vpn/compose.yaml   Headscale + Headplane stack
stacks/cerberus/headscale_vpn/config/        rendered app config
stacks/cerberus/headscale_vpn/data/          Headscale and Headplane state

stacks/athena/.env                           hypervisor-local values
stacks/daedalus/.env                         Docker VM host values
stacks/daedalus/*                            future app host stacks
```

## Cerberus Routing

```text
80/443  -> Caddy
          /admin  -> Headplane
          /       -> Headscale

network  -> edge
```

## Tailnet Defaults

```text
base domain    tailnet.cerberus.raulcorreia.dev
home domain    home.arpa
resolvers      9.9.9.9, 1.1.1.1, 1.0.0.1
split DNS      home.arpa -> 192.168.100.1
search domain  home.arpa
magic DNS      enabled
```

## Notes

```text
public edge     cerberus
firewall        hermes
lan gateway     192.168.100.1/24
isp upstream    192.168.178.1/24
```

## Related Docs

- `README.md` for the repo overview and command surface
- `docs/getting-started.md` for bring-up workflow
- `stacks/cerberus/reverse_proxy/README.md` for edge routing details
- `stacks/cerberus/headscale_vpn/README.md` for tailnet stack details
