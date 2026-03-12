var REG_NONE = NewRegistrar("none");
var DSP_CLOUDFLARE = NewDnsProvider("cloudflare");

D("raulcorreia.dev", REG_NONE, DnsProvider(DSP_CLOUDFLARE),
    CF_PROXY_DEFAULT_OFF,
    DefaultTTL(1),
    A("api.luxtodo", "31.56.39.248"),
    A("cerberus", "31.56.39.248"),
    A("vpn", "31.56.39.248"),
    CNAME("tailscale.cerberus", "vpn.raulcorreia.dev."),
    CNAME("luxtodo", "raulcorreia7.github.io.", CF_PROXY_ON),
    ALIAS("@", "raulcorreia7.github.io.", CF_PROXY_ON)
);
