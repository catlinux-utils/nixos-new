{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # wlroots sessions ship no polkit agent — HM runs it as a systemd user
    # service bound to graphical-session.target (activated by uwsm); the
    # agent itself must NOT also be installed system-side
    services.hyprpolkitagent.enable = true;
  };
}
