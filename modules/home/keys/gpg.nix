{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.gpg.enable {
    programs.gpg.enable = true;

    # ssh-agent support pairs with the keys-only OpenSSH server
    # (modules/nixos/ssh.nix) — SSH_AUTH_SOCK points at gpg-agent
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      # curses prompt works on every host, GUI or headless
      pinentry.package = pkgs.pinentry-curses;
    };
  };
}
