{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # runtime dep of the vendored QML: the media title comes from playerctl;
    # the resource widget opens btop in kitty (both already in the user
    # environment) and Noto Sans ships system-side (desktop/base.nix)
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
