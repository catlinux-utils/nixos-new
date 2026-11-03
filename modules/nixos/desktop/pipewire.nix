{
  lib,
  config,
  ...
}:
{
  options.cfg.audio.enable = lib.mkEnableOption "PipeWire audio";

  config = lib.mkIf config.cfg.audio.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = config.cfg.graphics.enable32Bit;
      };
      pulse.enable = true;
    };
  };
}
