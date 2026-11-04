# Secure Boot via lanzaboote — the UKI boot path. lzbt builds a signed UKI
# (kernel + initrd + cmdline) per generation into ESP/EFI/Linux; the signed
# systemd-boot it installs discovers them, so the boot menu stays short and
# non-NixOS entries (e.g. Windows Boot Manager, auto-listed) are easy to
# reach. Firmware Secure Boot may stay OFF — UKIs are signed regardless, and
# SB becomes a firmware toggle once enrolled.
#
# The flake input deliberately does NOT follow nixpkgs (see flake.nix): the
# module defaults its `package` to lanzaboote's own `lzbt` build (nixpkgs 26.05
# has no lzbt), and the module itself is officially nixos-unstable-only.
#
# First-use flow (per host): enable + rebuild → autoGenerateKeys creates the
# sbctl key bundle under pkiBundle on first boot → autoEnrollKeys stages
# PK/KEK/db for systemd-boot to enroll into the firmware on the next boot
# (includeMicrosoftKeys is upstream's default; loader.conf gets
# `secure-boot-enroll = force`). After enrollment the machine only boots
# signed artifacts.
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
      # short boot menu: one entry per kept generation, Windows easy to reach.
      # systemd-pcrlock (measuredBoot) hard-caps stored generations at 4
      configurationLimit = lib.mkDefault (
        if config.cfg.boot.secureBoot.measuredBoot.enable then 4 else 5
      );

      measuredBoot = lib.mkIf config.cfg.boot.secureBoot.measuredBoot.enable {
        enable = true;
        # firmware + GPT + boot-loader code + Secure Boot policy
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
