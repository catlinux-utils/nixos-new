{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.nix-index.enable {
    # channel-less command-not-found (channels are off in modules/nixos/nix.nix)
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # `,pkg` runs a binary straight from the store, resolved via the
    # nix-index database (build it once with `nix-index`)
    home.packages = [ pkgs.comma ];
  };
}
