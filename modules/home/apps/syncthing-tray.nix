{
  lib,
  osConfig,
  ...
}:
{
  # tray icon for the sync status — needs the system-side service
  # (cfg.syncthing) and a session with a StatusNotifier tray (cfg.desktop;
  # the quickshell bar hosts the icon on hyprland)
  config =
    lib.mkIf (osConfig.cfg.syncthing.enable && osConfig.cfg.desktop.enable) {
      services.syncthing.tray.enable = true;
    };
}
