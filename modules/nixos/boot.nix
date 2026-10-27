{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.boot = {
    enable = lib.mkEnableOption "systemd-boot with silent boot and zram";

    zenKernel.enable = lib.mkEnableOption "the zen kernel (linuxPackages_zen)";

    plymouth = {
      enable = lib.mkEnableOption "the Plymouth boot splash";
      theme = lib.mkOption {
        type = lib.types.str;
        default = "tribar";
        description = "Plymouth theme name.";
      };
    };
  };

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

    boot.kernelPackages = lib.mkIf config.cfg.boot.zenKernel.enable pkgs.linuxPackages_zen;

    boot.plymouth = lib.mkIf config.cfg.boot.plymouth.enable {
      enable = true;
      theme = config.cfg.boot.plymouth.theme;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };
  };
}
