{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.gnome.enable = lib.mkEnableOption "GNOME (GDM)";

  config = lib.mkIf config.cfg.desktop.gnome.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base

    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
