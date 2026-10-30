{
  lib,
  config,
  ...
}:
{
  options.cfg.openrazer.enable = lib.mkEnableOption "OpenRazer, the Razer-peripheral daemon";

  config = lib.mkIf config.cfg.openrazer.enable {
    hardware.openrazer.enable = true;

    # daemon access is group-based; the main user is the intended operator
    hardware.openrazer.users = [ config.cfg.user.name ];
  };
}
