# Power-management governors — pick at most one; the assertion below guards
# all three pairs (upstream only asserts power-profiles-daemon against the
# other two, not tlp-vs-auto-cpufreq). GNOME hosts already mkDefault
# power-profiles-daemon on, so flipping tlp/autoCpufreq on one collides with
# that default before this assertion even matters — disable it there or stay
# on ppd.
{
  lib,
  config,
  ...
}:
{
  options.cfg.power = {
    powerProfiles.enable = lib.mkEnableOption "power-profiles-daemon (the GNOME/KDE power governor)";

    tlp.enable = lib.mkEnableOption "TLP (battery-life tuned governor)";

    autoCpufreq.enable = lib.mkEnableOption "auto-cpufreq (automatic governor)";

    thermald.enable = lib.mkEnableOption "thermald, the (Intel) temperature management daemon";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion =
            lib.length (
              lib.filter lib.id [
                config.cfg.power.powerProfiles.enable
                config.cfg.power.tlp.enable
                config.cfg.power.autoCpufreq.enable
              ]
            ) <= 1;
          message = "cfg.power: powerProfiles, tlp and autoCpufreq are mutually exclusive — pick at most one governor";
        }
      ];
    }

    (lib.mkIf config.cfg.power.powerProfiles.enable {
      services.power-profiles-daemon.enable = true;
    })

    (lib.mkIf config.cfg.power.tlp.enable {
      services.tlp.enable = true;
    })

    (lib.mkIf config.cfg.power.autoCpufreq.enable {
      services.auto-cpufreq.enable = true;
    })

    (lib.mkIf config.cfg.power.thermald.enable {
      services.thermald.enable = true;
    })
  ];
}
