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

    # qt apps follow the same wallpaper palette through qt5ct/qt6ct + kvantum:
    # HM sets QT_QPA_PLATFORMTHEME (qt6ct registers the qt5ct name too, so one
    # var covers Qt5 and Qt6) and the qtct conf selects the kvantum style;
    # matugen renders the actual theme from the wallpaper
    # (kvantum-colors.kvconfig.tmpl → ~/.config/Kvantum/matugen/) at session
    # start, before any app launches. platformTheme.package is explicit
    # because setting it REPLACES HM's auto-detected packages (lib.findFirst):
    # the qtct plugins (theme/palette/font plumbing) plus the wayland
    # decorations — platformTheme "adwaita" used to auto-add those, "qtct"
    # doesn't, and without them Qt wayland windows fall back to Qt's gray
    # bradient titlebars
    qt = {
      enable = true;
      platformTheme = {
        name = "qtct";
        package = with pkgs; [
          libsForQt5.qt5ct
          qt6Packages.qt6ct
          qadwaitadecorations
          qadwaitadecorations-qt6
        ];
      };
      style.name = "kvantum";
      qt5ctSettings = {
        Appearance = {
          style = "kvantum";
          icon_theme = "Adwaita";
        };
        Fonts.general = ''"Noto Sans,10"'';
      };
      qt6ctSettings = {
        Appearance = {
          style = "kvantum";
          icon_theme = "Adwaita";
        };
        Fonts.general = ''"Noto Sans,10"'';
      };
    };

    # kvantum's theme selection — a static pointer at the matugen-rendered
    # theme dir (never rewritten at runtime; KvantumManager isn't shipped)
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [Theme]
      theme=matugen
    '';
  };
}
