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

    # dark gtk: settings.ini entries + the color-scheme key libadwaita reads
    gtk.enable = true;
    gtk.colorScheme = "dark";

    # gtk3 apps (nemo, gparted, pinta, nm-applet menus) can't be recolored by
    # the matugen gtk.css — GTK3's Adwaita only knows its theme_*-style
    # palette, not libadwaita's named colors; adw-gtk3 is a libadwaita replica
    # defining those colors, so the generated palette recolors it untouched
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };

    # without it GTK apps fall back to compiled Cantarell, which isn't installed
    gtk.font = {
      name = "Noto Sans";
      size = 10;
    };

    # icon theme for tray/status icons (hosts without a full DE otherwise get none)
    gtk.iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    # qt apps follow the palette via qt5ct/qt6ct + kvantum (one theme var for
    # Qt5+Qt6). platformTheme.package REPLACES HM's auto-detected packages —
    # list the qtct plugins + wayland decorations or Qt gets gray titlebars
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

    # kvantum theme selection — static pointer at the matugen-rendered theme dir
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [Theme]
      theme=matugen
    '';
  };
}
