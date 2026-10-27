{
  lib,
  osConfig,
  ...
}:
{
  # launcher for the SUPER+R bind in hyprland.lua; the rasi is vendored as a
  # plain file, same deal as hyprland.lua itself. HM's rofi module also
  # generates config.rasi on enable — this explicit xdg.configFile entry
  # outranks its mkDefault, so the vendored file is what ships.
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    programs.rofi.enable = true;
    xdg.configFile."rofi/config.rasi".source = ./rofi.rasi;
  };
}
