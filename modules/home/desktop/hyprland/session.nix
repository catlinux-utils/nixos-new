{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      # uwsm (system-side withUWSM) owns session/target activation; HM's own
      # hyprland-session.target stays off so wayland.* user units bind to
      # graphical-session.target instead
      systemd.enable = false;
    };

    # hyprland.lua vendored verbatim (copyable to non-NixOS machines). Do NOT
    # set settings/extraConfig: HM 26.05 (configType "lua") would generate the
    # same hypr/hyprland.lua path and fight this file.
    xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

    # shutdown menu for the SUPER+M bind (the bind falls back to `uwsm stop`)
    home.packages = [ pkgs.hyprshutdown ];

    # Electron/Chromium apps run native Wayland; uwsm sources ~/.config/uwsm/env
    xdg.configFile."uwsm/env".text = ''
      export ELECTRON_OZONE_PLATFORM_HINT=auto
      export NIXOS_OZONE_WL=1
    '';

    # pin the terminal uwsm picks for Terminal=true desktop entries (e.g. the
    # bar's btop launch): without this list the fallback scan can land on
    # kitty-open.desktop, which errors out in kitty's URL-opener dialog
    xdg.configFile."xdg-terminals.list".text = ''
      kitty.desktop
      -kitty-open.desktop
    '';
  };
}
