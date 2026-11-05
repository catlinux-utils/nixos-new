{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.git.enable {
    # delta moved to its own programs.delta tree on release-26.05
    programs.delta.enable = true;

    # GitHub CLI — one-time per-machine auth (device code + SSH key upload);
    # the credential helper only kicks in for HTTPS remotes — harmless with
    # the repo's SSH origin
    programs.gh.enable = true;

    programs.git = {
      enable = true;
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
