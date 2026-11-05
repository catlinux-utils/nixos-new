{
  lib,
  osConfig,
  ...
}:
{
  # rides the system desktop switch (no playback on headless hosts);
  # cfg.home.mpv.enable drops it per host (the installer ISO does)
  config = lib.mkIf (osConfig.cfg.desktop.enable && osConfig.cfg.home.mpv.enable) {
    programs.mpv.enable = true;
  };
}
