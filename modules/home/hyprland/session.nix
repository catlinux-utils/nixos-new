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
      # hyprland-session.target flow stays off so wayland.* user units bind
      # to graphical-session.target instead
      systemd.enable = false;
    };

    # the session config is the legacy flake's hyprland.lua vendored verbatim —
    # a plain file with no Nix interpolation, so it can be copied to non-NixOS
    # machines as-is. Hyprland (>= 0.53) loads it from ~/.config/hypr/ next to
    # the near-empty hyprland.conf HM generates.
    xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

    # shutdown menu for the SUPER+M bind (the bind itself falls back to
    # `uwsm stop` when the binary is missing)
    home.packages = [ pkgs.hyprshutdown ];

    # Electron/Chromium apps run native Wayland; uwsm sources ~/.config/uwsm/env
    xdg.configFile."uwsm/env".text = ''
      export ELECTRON_OZONE_PLATFORM_HINT=auto
      export NIXOS_OZONE_WL=1
    '';
  };
}
