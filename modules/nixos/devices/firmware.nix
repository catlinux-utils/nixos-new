{
  lib,
  config,
  ...
}:
{
  options.cfg.firmware.enable = lib.mkEnableOption "firmware: fwupd updates + redistributable firmware blobs";

  config = lib.mkIf config.cfg.firmware.enable {
    services.fwupd.enable = true;
    # GPU/Wi-Fi/BT firmware blobs + CPU microcode (nixos-hardware's
    # common-cpu-amd keys updateMicrocode to this)
    hardware.enableRedistributableFirmware = true;
  };
}
