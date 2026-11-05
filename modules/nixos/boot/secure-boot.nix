# Secure Boot via lanzaboote: signed UKIs per generation in ESP/EFI/Linux,
# discovered by its signed systemd-boot. Firmware SB may stay OFF — UKIs are
# signed regardless. Input does NOT follow nixpkgs (26.05 has no lzbt). First
# use: enable + rebuild → keys under pkiBundle → PK/KEK/db auto-enrolled next
# boot — only signed artifacts boot afterwards.
{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.cfg.boot.secureBoot = {
    enable = lib.mkEnableOption "UKI boot via lanzaboote (signed UKIs per generation; Secure Boot optional)";

    autoKeys.enable = lib.mkEnableOption ''
      automatic generation and enrollment of the Secure Boot key bundle
      (lanzaboote autoGenerateKeys + autoEnrollKeys): keys are created under
      the pkiBundle directory on first boot and written into the firmware NVRAM
      on the next reboot — the machine afterwards boots only signed artifacts
    '';

    measuredBoot.enable = lib.mkEnableOption ''
      systemd-pcrlock measured boot with a PCR policy (requires Secure Boot and
      TPM2; upstream caps boot generations at 4 with pcrlock — set
      automatically below). TPM2-backed LUKS auto-unlock via measuredBoot's
      autoCryptenroll stays a per-host follow-up: it needs the real LUKS
      device (Phase 2 disk decisions)
    '';
  };

  config = lib.mkIf config.cfg.boot.secureBoot.enable {
    # lanzaboote replaces systemd-boot with its signed variant (boot.loader.external)
    boot.loader.systemd-boot.enable = lib.mkForce false;
    # their recommended pair — enrollment itself happens at boot via loader.conf
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

    boot.lanzaboote = {
      enable = true;
      # sbctl key bundle, created by autoGenerateKeys on first boot
      pkiBundle = "/var/lib/sbctl";
      # short menu: one entry per kept generation; pcrlock (measuredBoot) caps
      # stored generations at 4
      configurationLimit = lib.mkDefault (
        if config.cfg.boot.secureBoot.measuredBoot.enable then 4 else 5
      );

      measuredBoot = lib.mkIf config.cfg.boot.secureBoot.measuredBoot.enable {
        enable = true;
        # firmware (0) + option ROMs (2) + boot-manager code (4) + SB policy (7)
        pcrs = lib.mkDefault [
          0
          2
          4
          7
        ];
      };

      autoGenerateKeys.enable = lib.mkIf config.cfg.boot.secureBoot.autoKeys.enable true;
      autoEnrollKeys.enable = lib.mkIf config.cfg.boot.secureBoot.autoKeys.enable true;
    };
  };
}
