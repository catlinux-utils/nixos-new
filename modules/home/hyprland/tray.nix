{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # tray icons for the bar (StatusNotifier): network applet + a volume mixer
    # (pavucontrol — middle-click the bar's volume widget to open it)
    services.network-manager-applet.enable = true;

    home.packages = [ pkgs.pavucontrol ];
  };
}
