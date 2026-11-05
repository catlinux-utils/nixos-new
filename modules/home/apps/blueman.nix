{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # blueman tray applet + GUI; the system switch (modules/nixos/devices/bluetooth.nix)
  # owns the bluez stack. The applet needs a StatusNotifier tray, so this also
  # gates on cfg.desktop.
  config = lib.mkIf (osConfig.cfg.bluetooth.enable && osConfig.cfg.desktop.enable) {
    services.blueman-applet.enable = true;

    home.packages = [ pkgs.blueman ];
  };
}
