{
  lib,
  config,
  ...
}:
{
  options.cfg.firmware.enable = lib.mkEnableOption "firmware updates (fwupd)";

  config = lib.mkIf config.cfg.firmware.enable {
    services.fwupd.enable = true;
  };
}
