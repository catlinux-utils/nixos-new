{
  lib,
  osConfig,
  ...
}:
{
  # opt-in screen recording — needs a session to capture (cfg.desktop)
  config = lib.mkIf (osConfig.cfg.home.obs.enable && osConfig.cfg.desktop.enable) {
    programs.obs-studio.enable = true;
  };
}
