{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # runtime dep of the session: playerctl drives the media-key binds in
    # hyprland.lua (the bar reads media via Mpris); the resource widget opens
    # btop in kitty (both already in the user environment)
    home.packages = [ pkgs.playerctl ];

    programs.quickshell = {
      enable = true;
      configs.default = ./quickshell;
      activeConfig = "default";
      # binds the user unit to graphical-session.target, which uwsm activates
      systemd.enable = true;
    };
  };
}
