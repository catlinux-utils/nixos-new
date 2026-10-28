{
  lib,
  config,
  ...
}:
{
  options.cfg.backup = {
    enable = lib.mkEnableOption "automated backup jobs (restic/borg passthrough)";

    restic.jobs = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Restic backup jobs, assigned verbatim to `services.restic.backups`
        (options verified on 26.05: `repository`/`repositoryFile`, `passwordFile`,
        `environmentFile`, `paths`, `pruneOpts`, `timerConfig`, ...). Credentials
        must come from sops-decrypted files — set `passwordFile` /
        `environmentFile` to `config.sops.secrets.<name>.path`, never to an
        interpolated value (store-leak rule, AGENTS.md).
      '';
    };

    borg.jobs = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Borg backup jobs, assigned verbatim to `services.borgbackup.jobs`.
        Credentials via `encryption.passCommand` / `environment` must reference
        sops-decrypted files (`config.sops.secrets.<name>.path`), never an
        interpolated value — same store-leak rule.
      '';
    };
  };

  config = lib.mkIf config.cfg.backup.enable (
    let
      cfg = config.cfg.backup;
    in
    {
      # everything else (service wiring, timers, assertions) is upstream's;
      # no host enables this until the Phase 3 master age key exists, since
      # the credentials these jobs need are sops-encrypted
      services.restic.backups = cfg.restic.jobs;

      services.borgbackup.jobs = cfg.borg.jobs;
    }
  );
}
