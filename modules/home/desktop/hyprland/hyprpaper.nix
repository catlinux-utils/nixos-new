{
  lib,
  config,
  osConfig,
  ...
}:
let
  # the running wallpaper: wallswitch overwrites this file on every pick and
  # palette.nix's oneshot seeds it from cfg.home.hyprland.wallpaper exactly
  # once — the repo-pinned path is only the install-time default
  current = "${config.home.homeDirectory}/.local/state/theming/current";
in
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
            preload = [ "${current}" ];
            wallpaper = [ ",${current}" ];
          };
        };
      };
}
