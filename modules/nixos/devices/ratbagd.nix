# Gaming-mouse configuration: ratbagd daemon + the piper GUI.
# Upstream renamed the module: services.ratbagd.enable (was services.ratbag.enable).
{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.ratbagd.enable = lib.mkEnableOption "ratbagd + piper, gaming-mouse configuration";

  config = lib.mkIf config.cfg.ratbagd.enable {
    services.ratbagd.enable = true;

    environment.systemPackages = [ pkgs.piper ];
  };
}
