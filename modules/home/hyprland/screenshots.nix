{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # tool for the screenshot binds in settings.nix:
    # Print = full screen, $mod+Print = region
    home.packages = [ pkgs.hyprshot ];
  };
}
