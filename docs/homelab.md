# Homelab

Small public edge on `cerberus`. Internal services stay behind Caddy by
default.

## Rule

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
```

## Homelab Network

```text
 .------------------------.     .------------------------.
 | ISP router / upstream  |---->| hermes / pfSense       |
 | 192.168.178.1/24       |     | 192.168.100.1/24       |
 '------------------------'     '-----------+------------'
                                              |
                    .----------+---------------+---------------+-------------.
                    |          |               |               |             |
            .-------v-------. .-v-----------. .-v---------. .--v----------. .-v----------.
            | chronos       | | athena      | | talos     | | laptops /   | | access     |
            | TrueNAS SCALE | | Proxmox     | | desktop   | | phone       | | point      |
            '---------------' '-------------' '-----------' '-------------' '------------'
```

## Where Things Live

```text
stacks/cerberus/.env                source of truth for cerberus values

stacks/cerberus/reverse_proxy/compose.yaml   Caddy stack
stacks/cerberus/reverse_proxy/config/        rendered Caddyfile
stacks/cerberus/reverse_proxy/data/          Caddy state

stacks/cerberus/headscale_vpn/compose.yaml   Headscale + Headplane stack
stacks/cerberus/headscale_vpn/config/        rendered app config
stacks/cerberus/headscale_vpn/data/          Headscale and Headplane state
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
