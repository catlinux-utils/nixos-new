{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # user-side gaming tools; the system stack lives in modules/nixos/gaming.nix
  config = lib.mkIf osConfig.cfg.gaming.enable {
    home.packages = with pkgs; [
      prismlauncher
      protonup-qt
    ];
  };
}
