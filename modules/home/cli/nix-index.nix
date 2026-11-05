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

    # `,pkg` runs a binary straight from the store via the nix-index database
    home.packages = [ pkgs.comma ];
  };
}
