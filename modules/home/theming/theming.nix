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

    # gtk3 apps (nemo, gparted, pinta, nm-applet menus) can't be recolored by
    # the matugen gtk.css: GTK3's built-in Adwaita only knows its own
    # theme_*-style palette, not libadwaita's named colors, and
    # gtk-application-prefer-dark-theme from settings.ini is app-controlled —
    # without a theme name they come up plain light Adwaita. adw-gtk3 is a
    # libadwaita replica for GTK3 that defines the same named colors, so the
    # generated palette recolors it untouched (HM writes gtk-theme-name to
    # gtk4's settings.ini too; libadwaita ignores it)
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };

    # without gtk-font-name GTK apps fall back to the compiled default
    # (Cantarell), which isn't installed
    gtk.font = {
      name = "Noto Sans";
      size = 10;
    };

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
