{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config =
    lib.mkIf (osConfig.cfg.desktop.hyprland.enable && osConfig.cfg.networking.networkManager.enable)
      {
        # tray icons for the bar (StatusNotifier): network applet + pavucontrol
        # (middle-click the bar's volume widget). The applet exports its icons
        # by name, so the package also sits in the system profile for quickshell
        # to resolve; gated on NM — useless without it
        services.network-manager-applet.enable = true;

        home.packages = [ pkgs.pavucontrol ];
      };
}
