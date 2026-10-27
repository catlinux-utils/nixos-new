{
  lib,
  osConfig,
  ...
}:
{
  config =
    lib.mkIf
      (osConfig.cfg.desktop.hyprland.enable && osConfig.cfg.home.hyprland.wallpaper != null)
      {
        services.hyprpaper = {
          enable = true;
          settings = {
            ipc = "on";
            splash = false;
            preload = [ "${osConfig.cfg.home.hyprland.wallpaper}" ];
            wallpaper = [ ",${osConfig.cfg.home.hyprland.wallpaper}" ];
          };
        };
      };
}
