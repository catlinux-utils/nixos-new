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
        background-color = "#1e1e2e";
        text-color = "#cdd6f4";
        border-color = "#89b4fa";
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
