# No PAM wiring needed: security.pam.services.<name>.fprintAuth defaults to
# services.fprintd.enable, so the (sufficient) pam_fprintd step joins every
# PAM stack once the daemon is on — GDM, console login and sudo all accept the
# reader after `fprintd-enroll`.
{
  lib,
  config,
  ...
}:
{
  options.cfg.fprintd.enable = lib.mkEnableOption "fprintd (fingerprint login; enroll with fprintd-enroll)";

  config = lib.mkIf config.cfg.fprintd.enable {
    services.fprintd.enable = true;
  };
}
