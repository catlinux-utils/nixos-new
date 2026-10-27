{
  lib,
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
      themeFile = "Catppuccin-Mocha";
      settings.confirm_os_window_close = 0;
    };
  };
}
