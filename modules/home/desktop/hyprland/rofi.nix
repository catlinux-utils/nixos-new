{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # launcher for the SUPER+R bind in hyprland.lua; the rasi is vendored as a
  # plain file, same deal as hyprland.lua itself. HM's rofi module can't be
  # enabled here — on enable it unconditionally generates config.rasi via
  # home.file, which conflicts with the vendored xdg.configFile entry — so
  # rofi ships as a plain package (HM's own default) and the config is ours.
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    home.packages = [ pkgs.rofi ];
    xdg.configFile."rofi/config.rasi".source = ./rofi.rasi;
  };
}
