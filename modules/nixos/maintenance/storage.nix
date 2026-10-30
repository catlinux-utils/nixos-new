{
  lib,
  config,
  ...
}:
{
  options.cfg.storage.enable = lib.mkEnableOption "storage maintenance (weekly fstrim, smartd)";

  config = lib.mkIf config.cfg.storage.enable {
    # weekly TRIM for SSDs (interval defaults to "weekly")
    services.fstrim.enable = true;

    # scans every detected drive (DEVICESCAN); mail notifications stay off
    # until an SMTP relay decision exists
    services.smartd.enable = true;
  };
}
