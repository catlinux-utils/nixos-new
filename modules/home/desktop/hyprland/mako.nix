{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  # the palette-rendered config only exists when a wallpaper seeds the theming
  # pipeline; mako exits when an explicit -c path is missing, so without a
  # wallpaper the packaged unit (built-in defaults) is the right one
  themed = osConfig.cfg.home.theming.enable && osConfig.cfg.home.hyprland.wallpaper != null;
in
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # notification daemon (Wayland); colors come from the runtime-generated
    # config (palette.nix → ~/.cache/theming/mako.conf) so they follow the wallpaper
    services.mako.enable = true;

    # Shadows the packaged mako.service outright (HM defines no unit — nothing
    # merges): must carry every packaged key or dbus activation breaks. When
    # gated off, the packaged unit is used unchanged.
    systemd.user.services.mako = lib.mkIf themed {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
          # wait for the palette so the first start already has colors
          "matugen-palette.service"
        ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecCondition = "/bin/sh -c '[ -n \"$WAYLAND_DISPLAY\" ]'";
        ExecStart = "${pkgs.mako}/bin/mako -c ${config.home.homeDirectory}/.cache/theming/mako.conf";
        ExecReload = "${pkgs.mako}/bin/makoctl reload";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
