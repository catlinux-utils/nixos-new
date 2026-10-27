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
      settings = {
        General.Experimental = true; # battery % of connected devices
        Policy.AutoEnable = true; # power on adapters as they appear
      };
    };

    # tray applet — the hosts enabling this are desktop sessions anyway
    services.blueman.enable = true;
  };
}
