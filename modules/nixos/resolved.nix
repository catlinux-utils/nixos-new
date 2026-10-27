{
  lib,
  config,
  ...
}:
{
  options.cfg.networking.resolved.enable =
    lib.mkEnableOption "systemd-resolved with DNS-over-TLS (Cloudflare upstreams)";

  config = lib.mkIf config.cfg.networking.resolved.enable {
    # DoT upstreams — the #suffix is the TLS SNI each server expects
    networking.nameservers = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
      "2606:4700:4700::1111#one.one.one.one"
      "2606:4700:4700::1001#one.one.one.one"
    ];

    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNSOverTLS = true;
        LLMNR = false;
        # .local resolution runs through avahi (nssmdns4), not resolved
        MulticastDNS = false;
        # NOTE: wake me up in 20 years when DNSSEC is at least partially working
        DNSSEC = false;
        FallbackDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };
    };
  };
}
