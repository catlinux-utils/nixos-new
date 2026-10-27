{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.hyprland.enable = lib.mkEnableOption "Hyprland";

  config = lib.mkIf config.cfg.desktop.hyprland.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base
    cfg.graphics.enable = lib.mkDefault true;
    cfg.audio.enable = lib.mkDefault true;

    # session runs through uwsm: it activates graphical-session.target, which
    # is where the home-side user units (waybar, hyprpaper, polkit agent) bind
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    security.polkit.enable = true;
  };
}
