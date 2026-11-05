# Chrony time sync — replaces systemd-timesyncd (the upstream module
# mkForce-disables timesyncd itself). NTS (authenticated NTP) on by default,
# pointed at Cloudflare's NTS-capable servers — the default
# networking.timeServers pool speaks plain NTP only and breaks NTS.
{
  lib,
  config,
  ...
}:
{
  options.cfg.chrony.enable = lib.mkEnableOption "chrony time sync (services.chrony, NTS on)";

  config = lib.mkIf config.cfg.chrony.enable {
    services.chrony = {
      enable = true;
      enableNTS = lib.mkDefault true;
      servers = lib.mkDefault [ "time.cloudflare.com" ];
    };
  };
}
