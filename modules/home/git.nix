{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.git.enable {
    programs.git = {
      enable = true;
      delta.enable = true;
      lfs.enable = true;
      settings = lib.mkMerge [
        { init.defaultBranch = "main"; }
        (lib.mkIf (osConfig.cfg.home.git.name != null) {
          user.name = osConfig.cfg.home.git.name;
        })
        (lib.mkIf (osConfig.cfg.home.git.email != null) {
          user.email = osConfig.cfg.home.git.email;
        })
      ];
    };
  };
}
