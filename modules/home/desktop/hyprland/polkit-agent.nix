{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # wlroots sessions ship no polkit agent — run as a user service bound to
    # graphical-session.target (uwsm); must NOT also be installed system-side
    services.hyprpolkitagent.enable = true;
  };
}
