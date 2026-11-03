{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # tool for the screenshot bind in hyprland.lua ($mod+Shift+S, region)
    home.packages = [ pkgs.hyprshot ];
  };
}
