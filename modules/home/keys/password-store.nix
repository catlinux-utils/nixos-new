{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.password-store.enable {
    # pass needs a GPG key in the agent (modules/home/gpg.nix) on first use:
    # `pass init <gpg-id>`
    programs.password-store.enable = true;
  };
}
