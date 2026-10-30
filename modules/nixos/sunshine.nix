# Self-hosted game-stream host for Moonlight clients. Upstream runs it as a
# user service on graphical-session.target (uwsm activates that on Hyprland),
# derives the firewall ports from settings.port and publishes via avahi.
{
  lib,
  config,
  ...
}:
{
  options.cfg.sunshine.enable = lib.mkEnableOption "Sunshine, the game-stream host";

  config = lib.mkIf config.cfg.sunshine.enable {
    services.sunshine = {
      enable = true;
      # LAN streaming is the point; a host can still override to closed
      openFirewall = lib.mkDefault true;
    };
  };
}
