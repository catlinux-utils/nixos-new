{
  lib,
  osConfig,
  ...
}:
{
  # user-side daemon/indicator; the system switch owns package + firewall ports
  config = lib.mkIf osConfig.cfg.kdeconnect.enable {
    services.kdeconnect.enable = true;
  };
}
