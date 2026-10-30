# Phase 6 — Secure Boot via lanzaboote. Dormant: nothing enables it yet. The
# flake input deliberately does NOT follow nixpkgs (see flake.nix): the module
# defaults its `package` to lanzaboote's own `lzbt` build (nixpkgs 26.05 has no
# lzbt), and the module itself is officially nixos-unstable-only — enable per
# host only after a real eval on a Nix machine, on UEFI hardware.
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
    enable = lib.mkEnableOption "Secure Boot via lanzaboote (signed systemd-boot)";

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
      # systemd-pcrlock hard-caps stored generations at 4
      configurationLimit = lib.mkIf config.cfg.boot.secureBoot.measuredBoot.enable 4;

      measuredBoot = lib.mkIf config.cfg.boot.secureBoot.measuredBoot.enable {
        enable = true;
        # firmware + GPT + boot-loader code + Secure Boot policy
        pcrs = lib.mkDefault [ 0 2 4 7 ];
      };

      autoGenerateKeys.enable = lib.mkIf config.cfg.boot.secureBoot.autoKeys.enable true;
      autoEnrollKeys.enable = lib.mkIf config.cfg.boot.secureBoot.autoKeys.enable true;
    };
  };
}
