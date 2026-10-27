{
  lib,
  config,
  ...
}:
{
  options.cfg.tailscale.enable = lib.mkEnableOption "tailscale (mesh VPN, remote access)";

  config = lib.mkIf config.cfg.tailscale.enable {
    services.tailscale = {
      enable = true;
      # direct connections need the tunnel port (UDP 41641) open; hosts stay
      # mesh clients — subnet routing / exit nodes are a per-host decision
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    # first auth is interactive: run `tailscale up` once per host
  };
}
