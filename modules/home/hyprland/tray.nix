{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # tray icons for the bar (StatusNotifier): network applet + a volume mixer
    services.network-manager-applet.enable = true;

    home.packages = [ pkgs.pavucontrol ];
  };
}
