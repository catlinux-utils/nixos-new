# Power-management governors — pick at most one; the assertion below covers all
# three (upstream only asserts power-profiles-daemon vs the other two, not
# tlp-vs-auto-cpufreq). GNOME hosts mkDefault ppd on — flipping tlp/autoCpufreq
# there collides with that default; disable it or stay on ppd.
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

    # 26.05 renamed the flat lidSwitch option to
    # services.logind.settings.Login.HandleLidSwitch (extraConfig gone)
    lidSwitch = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "ignore"
          "poweroff"
          "reboot"
          "halt"
          "kexec"
          "suspend"
          "hibernate"
          "hybrid-sleep"
          "suspend-then-hibernate"
          "lock"
        ]
      );
      default = null;
      description = "What logind does when the lid closes (HandleLidSwitch); null leaves upstream's default (suspend).";
    };
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

    (lib.mkIf (config.cfg.power.lidSwitch != null) {
      services.logind.settings.Login.HandleLidSwitch = config.cfg.power.lidSwitch;
    })
  ];
}
