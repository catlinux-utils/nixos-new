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
      # matugen palette colors; kitty rejects absolute includes, so the path is
      # relative to ~/.config/kitty/ — globinclude silently skips a missing
      # file and kitty defaults apply until the first palette render
      settings.globinclude = "../../.cache/theming/kitty-colors.conf";
      settings.confirm_os_window_close = 0;
      settings.scrollback_lines = 10000;
      settings.enable_audio_bell = false;
      # see-through terminal over the wallpaper; tweak 0–1 (1 = opaque)
      settings.background_opacity = "0.5";
    };
  };
}
