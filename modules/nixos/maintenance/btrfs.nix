{
  lib,
  config,
  ...
}:
{
  options.cfg.btrfsMaintenance.enable = lib.mkEnableOption ''
    Btrfs maintenance: weekly scrub + monthly balance. For Btrfs hosts; hosts
    pick the aggressiveness via cfg.btrfsMaintenance.light (laptop).
  '';

  options.cfg.btrfsMaintenance.light = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Lighter schedule for battery/portable machines: monthly scrub, no
      balance timer. Only applies when cfg.btrfsMaintenance.enable is set.
    '';
  };

  # Self-gating: switches set on hosts whose generated hardware config isn't
  # installed yet (placeholder, no fileSystems) stay assertion-clean.
  config =
    lib.mkIf
      (
        config.cfg.btrfsMaintenance.enable
        && builtins.any (fs: fs.fsType or "" == "btrfs") (builtins.attrValues config.fileSystems)
      )
      {
        services.btrfs.autoScrub = {
          enable = true;
          interval = if config.cfg.btrfsMaintenance.light then "monthly" else "weekly";
        };

        systemd.timers.btrfs-balance = lib.mkIf (!config.cfg.btrfsMaintenance.light) {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
          };
        };
        systemd.services.btrfs-balance = lib.mkIf (!config.cfg.btrfsMaintenance.light) {
          wantedBy = [ "btrfs-balance.timer" ];
          serviceConfig.Type = "oneshot";
          script = "btrfs balance start -dusage=50 /";
        };
      };
}
