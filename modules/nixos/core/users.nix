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
      default = "cat";
      description = "Name of the main (and only) user account.";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "ThePolishcat";
      description = "Full name (GECOS) of the main user.";
    };
    initialPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "cat";
      description = ''
        Plaintext password applied at first deploy only (`users.users.<name>.initialPassword`).
        Default is "cat" (replace with your own in the host file).
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
      # mkDefault: upstream installation-device.nix (imported by the installer
      # host) sets "" for its passwordless `nixos` user and must win over this
      # placeholder on live media
      initialPassword = lib.mkIf (config.cfg.user.initialPassword != null) (
        lib.mkDefault config.cfg.user.initialPassword
      );
    };
  };
}
