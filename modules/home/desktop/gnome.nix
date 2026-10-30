{
  lib,
  osConfig,
  ...
}:
{
  # rides the system GNOME switch; gtk theming + the dark color scheme live
  # in theming.nix (shared across desktops, which also enables HM dconf)
  config = lib.mkIf osConfig.cfg.desktop.gnome.enable {
    # minimal sane defaults — anything set here is still adjustable in GNOME
    # Settings; add dconf entries as preferences emerge
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };
    };
  };
}
