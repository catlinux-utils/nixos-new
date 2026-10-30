# Custom-keyboard firmware flashing: udev rules only (flashers like qmk or
# wally-cli are user-environment choices, not system wiring).
{
  lib,
  config,
  ...
}:
{
  options.cfg.keyboard = {
    qmk.enable = lib.mkEnableOption "QMK keyboard flashing udev rules";

    qmk.keychronSupport = lib.mkEnableOption "Keychron QMK udev rules";

    zsa.enable = lib.mkEnableOption "ZSA keyboard (ErgoDox EZ, Planck EZ, Moonlander) flashing udev rules";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.keyboard.qmk.enable {
      hardware.keyboard.qmk.enable = true;
      hardware.keyboard.qmk.keychronSupport = config.cfg.keyboard.qmk.keychronSupport;
    })

    (lib.mkIf config.cfg.keyboard.zsa.enable {
      hardware.keyboard.zsa.enable = true;
    })
  ];
}
