{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.direnv.enable {
    # per-project dev shells; nix.nix sets keep-outputs/keep-derivations so
    # dev-shell dependencies survive garbage collection
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
