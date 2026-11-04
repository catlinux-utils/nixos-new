{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.git.enable {
    # delta moved to its own programs.delta tree on release-26.05
    programs.delta.enable = true;

    # GitHub CLI — one-time per-machine auth (device code) that generates and
    # uploads an SSH key and wires the credential helper; see INSTALL.md's
    # "One-time GitHub auth" section. The credential helper only kicks in for
    # HTTPS remotes — harmless with the repo's SSH origin.
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
