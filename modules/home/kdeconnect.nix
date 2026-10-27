{
  lib,
  osConfig,
  ...
}:
{
  # user-side daemon/indicator; the system switch (modules/nixos/kdeconnect.nix)
  # owns the package and the firewall ports
  config = lib.mkIf osConfig.cfg.kdeconnect.enable {
    services.kdeconnect.enable = true;
  };
}
