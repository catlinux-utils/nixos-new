{
  lib,
  config,
  ...
}:
{
  options.cfg.geolocation.enable =
    lib.mkEnableOption "location services (geoclue2 — night light, automatic timezone)";

  config = lib.mkIf config.cfg.geolocation.enable {
    services.geoclue2.enable = true;
  };
}
