{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.enable {
    # HM-side dconf backend — without it, dconf.settings here and in gnome.nix
    # are silently dropped; the system-side db comes from desktop/base.nix
    dconf.enable = true;

    # dark gtk: settings.ini entries (gtk-application-prefer-dark-theme,
    # gtk-interface-color-scheme) plus the color-scheme gsettings key
    # libadwaita and portal-following apps read
    gtk.enable = true;
    gtk.colorScheme = "dark";

    # icon theme for tray/status icons (nm-applet etc.) — hosts without a full
    # DE (e.g. the live ISO) otherwise have no icon theme at all and the bar
    # renders missing-icon placeholders
    gtk.iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    # qt apps follow adwaita — HM auto-detects the style packages
    # (adwaita-qt, adwaita-qt6) and wayland decorations (qadwaitadecorations)
    # from these names
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };
  };
}
