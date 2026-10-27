{
  lib,
  config,
  ...
}:
{
  options.cfg.ssh = {
    enable = lib.mkEnableOption "the OpenSSH server (keys only)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "Port the SSH server listens on.";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        SSH public keys authorized for the main user. On a fresh host with
        keys-only SSH these (or root's keys) must include the admin key,
        or nothing can log in.
      '';
    };
  };

  config = lib.mkIf config.cfg.ssh.enable {
    services.openssh = {
      enable = true;
      ports = [ config.cfg.ssh.port ];
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    users.users.${config.cfg.user.name}.openssh.authorizedKeys.keys =
      config.cfg.ssh.authorizedKeys;
  };
}
