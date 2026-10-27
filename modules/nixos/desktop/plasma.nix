{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma 6 (SDDM)";

  config = lib.mkIf config.cfg.desktop.plasma.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;
  };
}
