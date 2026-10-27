{
  lib,
  config,
  ...
}:
{
  options.cfg.bluetooth.enable = lib.mkEnableOption "bluetooth (bluez + blueman applet)";

  config = lib.mkIf config.cfg.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # tray applet — the hosts enabling this are desktop sessions anyway
    services.blueman.enable = true;
  };
}
