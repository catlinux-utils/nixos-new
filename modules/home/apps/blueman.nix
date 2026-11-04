{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # blueman tray applet + GUI (blueman-manager, blueman-adapters); the system
  # switch (modules/nixos/devices/bluetooth.nix) owns the bluez stack. the
  # applet is only useful with a StatusNotifier tray (the quickshell bar), so
  # this also gates on cfg.desktop.
  config = lib.mkIf (osConfig.cfg.bluetooth.enable && osConfig.cfg.desktop.enable) {
    services.blueman-applet.enable = true;

    home.packages = [ pkgs.blueman ];
  };
}
