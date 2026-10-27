{
  lib,
  osConfig,
  ...
}:
{
  # a desktop audio app: needs PipeWire (cfg.audio), a session to show its
  # window in (cfg.desktop — which also provides dconf) and its own switch
  config =
    lib.mkIf
      (osConfig.cfg.home.easyeffects.enable && osConfig.cfg.audio.enable && osConfig.cfg.desktop.enable)
      {
        # EQ/compressor presets live in $XDG_DATA_HOME/easyeffects — drop JSON
        # files there or wire them via extraPresets once tuned
        services.easyeffects.enable = true;
      };
}
