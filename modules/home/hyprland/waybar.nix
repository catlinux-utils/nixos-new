{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %d %B %Y}";
        };

        pulseaudio.format = "{volume}%";

        network = {
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "{ipaddr}";
          format-disconnected = "offline";
        };

        battery.format = "{capacity}%"; # auto-hides when there is no battery

        tray = {
          icon-size = 18;
          spacing = 8;
        };
      };

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", sans-serif;
          font-size: 13px;
        }

        window#waybar {
          background: rgba(30, 30, 46, 0.9);
          color: #cdd6f4;
        }
      '';
    };
  };
}
