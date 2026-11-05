# Phase 6 — own binary cache via upstream services.atticd. Dormant; when it
# lands (server first) cfg.attic.environmentFile must point at a sops-decrypted
# file (store-leak rule — see secrets.nix).
{
  lib,
  config,
  ...
}:
{
  options.cfg.attic = {
    enable = lib.mkEnableOption "the attic binary-cache server (services.atticd)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "TCP port the atticd API listens on (opened in the firewall).";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Env file providing ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 (upstream
        requires it; generate the key with
        `openssl genrsa -traditional 4096 | base64 -w0`). Point it at a
        sops-decrypted secret file, e.g. config.sops.secrets.atticEnv.path.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "settings.toml passthrough (database, storage, chunking…).";
    };
  };

  config = lib.mkIf config.cfg.attic.enable {
    # fail at eval time, not at service start
    assertions = [
      {
        assertion = config.cfg.attic.environmentFile != null;
        message = ''
          cfg.attic.environmentFile must point at a sops-decrypted env file
          (e.g. config.sops.secrets.atticEnv.path) containing
          ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 — services.atticd refuses to
          run without it.
        '';
      }
    ];

    services.atticd = {
      enable = true;
      environmentFile = config.cfg.attic.environmentFile;
      settings = config.cfg.attic.settings // {
        listen = "[::]:${toString config.cfg.attic.port}";
      };
    };

    networking.firewall.allowedTCPPorts = [ config.cfg.attic.port ];
  };
}
