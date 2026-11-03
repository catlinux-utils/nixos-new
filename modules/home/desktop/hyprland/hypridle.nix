{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # idle daemon: dim at 2.5 min, lock at 5, dpms off at 5.5, suspend at 15
    services.hypridle = {
      enable = true;
      # uwsm activates graphical-session.target directly (HM's own
      # hyprland-session.target stays off — see session.nix)
      systemdTarget = "graphical-session.target";
      settings = {
        general = {
          # pidof guard so repeated idle/sleep events don't stack lockers
          lock_cmd = "pidof hyprlock || hyprlock";
          # lock before the machine goes to sleep
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
        };

        listener = [
          {
            timeout = 150;
            on-timeout = "brightnessctl -s set 10"; # avoid 0 on OLED panels
            on-resume = "brightnessctl -r";
          }
          {
            timeout = 150;
            on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
            on-resume = "brightnessctl -rd rgb:kbd_backlight";
          }
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 900;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };

    # backlight control for the dim/restore listeners
    home.packages = [ pkgs.brightnessctl ];
  };
}
