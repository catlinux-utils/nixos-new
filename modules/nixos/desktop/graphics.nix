{
  lib,
  config,
  ...
}:
{
  options.cfg.graphics = {
    enable = lib.mkEnableOption "the OpenGL/VA-API base GPU stack";
    enable32Bit = lib.mkEnableOption "32-bit graphics support (e.g. Steam)";
  };

  config = lib.mkIf config.cfg.graphics.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = config.cfg.graphics.enable32Bit;
      # GPU-specific extraPackages (nvidia/ROCm) come from nixos-hardware in Phase 2
    };
  };
}
