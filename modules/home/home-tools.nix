{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.tools.enable {
    programs.home-manager.enable = true;
  };
}
