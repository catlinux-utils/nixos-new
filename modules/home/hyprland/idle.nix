{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # idle daemon: lock after 10 min, dpms off after 15
    services.hypridle = {
      enable = true;
      # uwsm activates graphical-session.target directly (HM's own
      # hyprland-session.target stays off — see settings.nix)
      systemdTarget = "graphical-session.target";
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };

        listener = [
          {
            timeout = 600;
            on-timeout = "hyprlock";
          }
          {
            timeout = 900;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
