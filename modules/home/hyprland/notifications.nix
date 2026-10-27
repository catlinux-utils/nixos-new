{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # notification daemon (Wayland); config lands in ~/.config/mako/config
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        font = "JetBrainsMono Nerd Font 11";
        # match the quickshell bar's Theme.qml (col0 / colFg / col1)
        background-color = "#18161a";
        text-color = "#ebeffe";
        border-color = "#707f9b";
        border-size = 2;
        border-radius = 8;
        default-timeout = 5000;
        icons = true;
        markup = true;
        layer = "top";
      };
    };
  };
}
