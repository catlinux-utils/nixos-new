{
  lib,
  config,
  ...
}:
{
  options.cfg.kdeconnect.enable = lib.mkEnableOption "KDE Connect (phone pairing)";

  config = lib.mkIf config.cfg.kdeconnect.enable {
    # the 26.05 module opens its discovery/pairing ports (1714–1764 TCP+UDP)
    # unconditionally when enabled — no firewall wiring needed here
    programs.kdeconnect.enable = true;
  };
}
