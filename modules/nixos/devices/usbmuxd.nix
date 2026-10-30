# iPhone/iPad over USB: the usbmuxd multiplexing daemon (udev rule + system
# user/group upstream) plus libimobiledevice's pairing CLI (idevicepair).
{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.usbmuxd.enable = lib.mkEnableOption "usbmuxd, iPhone/iPad USB pairing and tethering";

  config = lib.mkIf config.cfg.usbmuxd.enable {
    services.usbmuxd.enable = true;

    environment.systemPackages = [ pkgs.libimobiledevice ];
  };
}
