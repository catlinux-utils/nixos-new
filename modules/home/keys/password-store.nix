{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.password-store.enable {
    # first use needs a GPG key in the agent: `pass init <gpg-id>`
    programs.password-store.enable = true;
  };
}
