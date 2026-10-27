{
  lib,
  osConfig,
  ...
}:
{
  # launcher for the SUPER+R bind in hyprland.lua; the rasi is vendored as a
  # plain file, same deal as hyprland.lua itself
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    programs.rofi.enable = true;
    xdg.configFile."rofi/config.rasi".source = ./rofi.rasi;
  };
}
