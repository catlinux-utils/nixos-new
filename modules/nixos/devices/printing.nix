{
  lib,
  config,
  ...
}:
{
  options.cfg.printing.enable = lib.mkEnableOption "printing (CUPS) and scanning (SANE)";

  config = lib.mkIf config.cfg.printing.enable {
    # CUPS admin UI on 127.0.0.1:631; per-printer drivers join host config
    services.printing.enable = true;

    # printer discovery via mDNS (.local hostnames resolve for the GUI)
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.sane.enable = true;
    users.users.${config.cfg.user.name}.extraGroups = [
      "scanner"
      "lp"
    ];
  };
}
