# Phase 6 — scheduled auto-updates via upstream system.autoUpgrade. Dormant:
# no host flips it yet — PLAN leaves the manual-nh-vs-auto trade-off to each
# host. Flake-aware: pulls this repo from cfg.nh.flakeDir (--refresh is set
# automatically in flake mode).
{
  lib,
  config,
  ...
}:
{
  options.cfg.updates.auto = {
    enable = lib.mkEnableOption "scheduled automatic system updates (flake-aware system.autoUpgrade)";

    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:40";
      description = "systemd timer schedule for the upgrade run (OnCalendar-style).";
    };

    operation = lib.mkOption {
      type = lib.types.enum [ "switch" "boot" ];
      default = "switch";
      description = ''
        Activate the new generation immediately (switch) or only stage it as
        the boot default for the next reboot (boot) — boot is the conservative
        choice for headless hosts.
      '';
    };

    allowReboot = lib.mkEnableOption "rebooting into the new generation when the upgrade requires it";
  };

  config = lib.mkIf config.cfg.updates.auto.enable {
    system.autoUpgrade = {
      enable = true;
      flake = toString config.cfg.nh.flakeDir;
      # flake mode: no channel mechanism (nix.nix keeps channels off anyway)
      upgrade = false;
      inherit (config.cfg.updates.auto)
        dates
        operation
        allowReboot
        ;
    };

    # nix.gc.automatic stays off — nh.clean owns garbage collection.
  };
}
