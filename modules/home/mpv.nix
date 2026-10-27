{
  lib,
  osConfig,
  ...
}:
{
  # rides the system desktop switch — no video playback on headless hosts
  config = lib.mkIf osConfig.cfg.desktop.enable {
    programs.mpv.enable = true;
  };
}
