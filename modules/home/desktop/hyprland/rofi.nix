{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # launcher for the SUPER+R bind in hyprland.lua; the rasi is vendored as a
  # plain file, same deal as hyprland.lua. HM's rofi module can't be enabled
  # here — it unconditionally generates config.rasi via home.file, conflicting
  # with this xdg.configFile entry.
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    home.packages = [ pkgs.rofi ];
    xdg.configFile."rofi/config.rasi".source = ./rofi.rasi;
  };
}
