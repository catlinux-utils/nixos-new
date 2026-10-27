{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # adwaita cursor for the session and gtk apps
    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };

    # uwsm sources ~/.config/uwsm/env-* at session start; the Hyprland cursor
    # env gets its own file (env-hyprland) so each writer stays separate
    xdg.configFile."uwsm/env-hyprland".text = ''
      export HYPRCURSOR_THEME=Adwaita
      export HYPRCURSOR_SIZE=24
    '';
  };
}
