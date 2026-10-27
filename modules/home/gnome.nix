{
  lib,
  osConfig,
  ...
}:
{
  # rides the system GNOME switch; system-side dconf comes from
  # desktop/base.nix (programs.dconf.enable)
  config = lib.mkIf osConfig.cfg.desktop.gnome.enable {
    # settings.ini fallback for toolkit apps running outside the GNOME session
    gtk.enable = true;

    # minimal sane defaults — anything set here is still adjustable in GNOME
    # Settings; add dconf entries as preferences emerge
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        clock-show-weekday = true;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };
    };
  };
}
