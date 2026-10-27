{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "polishcat";
      description = "Name of the main (and only) user account.";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "ThePolishcat";
      description = "Full name (GECOS) of the main user.";
    };
    initialHashedPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Hashed password applied at first deploy only (`mkpasswd -m sha-512`).
        Leave null only when SSH keys for the main user are already in place:
        with no password set the account is locked — key-SSH works, but sudo,
        console and display-manager login all fail.
      '';
    };
  };

  config = {
    # so the login shell below is a valid /etc/shells entry
    programs.zsh.enable = true;

    users.users.${config.cfg.user.name} = {
      isNormalUser = true;
      description = config.cfg.user.fullName;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      initialHashedPassword =
        lib.mkIf (config.cfg.user.initialHashedPassword != null)
          config.cfg.user.initialHashedPassword;
    };
  };
}
