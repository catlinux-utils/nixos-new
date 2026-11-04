{
  lib,
  config,
  ...
}:
{
  options.cfg.bluetooth.enable = lib.mkEnableOption "bluetooth (bluez stack)";

  config = lib.mkIf config.cfg.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General.Experimental = true; # battery % of connected devices
        Policy.AutoEnable = true; # power on adapters as they appear
      };
    };

    # the blueman tray applet lives home-side (modules/home/apps/blueman.nix),
    # gated on this same switch
  };
}
