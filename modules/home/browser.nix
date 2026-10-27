{
  lib,
  osConfig,
  ...
}:
{
  # rides the system desktop switch — no browser on headless hosts
  config = lib.mkIf osConfig.cfg.desktop.enable {
    # policies/profiles slots in here once wanted (search defaults, extensions)
    programs.firefox.enable = true;
  };
}
