{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # Each file in this folder owns distinct keys of
  # wayland.windowManager.hyprland.settings — keep one writer per key.
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      # uwsm (system-side withUWSM) owns session/target activation; HM's own
      # hyprland-session.target flow stays off so wayland.* user units bind
      # to graphical-session.target instead
      systemd.enable = false;

      settings = {
        "$mod" = "SUPER";

        monitor = [ ",preferred,auto,1" ];

        # native Wayland for Electron/Chromium apps (Slack, Discord, VS Code...)
        env = [
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "NIXOS_OZONE_WL,1"
        ];

        bind = [
          "$mod, Return, exec, kitty"
          "$mod, D, exec, wofi --show drun"
          "$mod, Q, killactive"
          "$mod, M, exit"
          "$mod, Space, togglefloating"
          "$mod, F, fullscreen"
          "$mod, L, exec, hyprlock"
          ", Print, exec, hyprshot -m output -o /tmp -f screenshot.png"
          "$mod, Print, exec, hyprshot -m region -o /tmp -f screenshot.png"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };

        decoration.rounding = 8;
      };
    };

    # app launcher (bound to $mod+D above)
    home.packages = [ pkgs.wofi ];
  };
}
