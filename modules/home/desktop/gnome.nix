{
  lib,
  osConfig,
  ...
}:
{
  # rides the system GNOME switch; gtk theming lives in theming.nix
  config = lib.mkIf osConfig.cfg.desktop.gnome.enable {
    # minimal sane defaults, adjustable in GNOME Settings; extend as
    # preferences emerge
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
