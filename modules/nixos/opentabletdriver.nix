# Drawing-tablet driver: udev rules + user service on graphical-session.target;
# upstream blacklists the conflicting hid-uclogic/wacom kernel modules and
# defaults daemon.enable to true.
{
  lib,
  config,
  ...
}:
{
  options.cfg.opentabletdriver.enable = lib.mkEnableOption "OpenTabletDriver, the drawing-tablet driver";

  config = lib.mkIf config.cfg.opentabletdriver.enable {
    hardware.opentabletdriver.enable = true;
  };
}
