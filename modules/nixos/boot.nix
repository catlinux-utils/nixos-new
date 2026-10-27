{
  lib,
  config,
  ...
}:
{
  options.cfg.boot.enable = lib.mkEnableOption "systemd-boot with silent boot and zram";

  config = lib.mkIf config.cfg.boot.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        # belt-and-suspenders alongside `nh clean`
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    boot.initrd.systemd.enable = true;
    boot.tmp.cleanOnBoot = true;

    # silent boot
    boot.consoleLogLevel = 3;
    boot.kernelParams = [ "quiet" ];

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };
  };
}
