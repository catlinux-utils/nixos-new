{
  lib,
  config,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.terminal.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 11;
      };
      # colors from the matugen palette (modules/home/palette.nix):
      # globinclude silently skips a missing file — kitty defaults apply
      # until the first palette render
      settings.globinclude = "${config.home.homeDirectory}/.cache/theming/kitty-colors.conf";
      settings.confirm_os_window_close = 0;
    };
  };
}
