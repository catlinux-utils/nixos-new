{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # tray icons for the bar (StatusNotifier): network applet + a volume mixer
    # (pavucontrol — middle-click the bar's volume widget to open it).
    # the applet exports its icons by name, so the package also sits in the
    # system profile (nixos/desktop/hyprland.nix) for quickshell to resolve
    services.network-manager-applet.enable = true;

    home.packages = [ pkgs.pavucontrol ];
  };
}
