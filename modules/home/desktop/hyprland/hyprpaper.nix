{
  lib,
  config,
  osConfig,
  ...
}:
let
  # the running wallpaper: wallswitch overwrites it on every pick; palette.nix's
  # oneshot seeds it once — the repo-pinned path is only the install-time default
  current = "${config.home.homeDirectory}/.local/state/theming/current";
in
{
  config =
    lib.mkIf
      (
        osConfig.cfg.desktop.hyprland.enable
        && osConfig.cfg.home.theming.enable
        && osConfig.cfg.home.hyprland.wallpaper != null
      )
      {
        services.hyprpaper.enable = true;

        # HM's module only creates the systemd unit — the binary never lands on
        # the user PATH, and waypaper's `shutil.which("hyprpaper")` check then
        # fails ("no wallpaper backends" dialog)
        home.packages = [ config.services.hyprpaper.package ];

        # hyprpaper 0.8 dropped the old preload/wallpaper= syntax and HM's
        # settings renderer still targets it — conf written verbatim, settings
        # stay empty so HM generates nothing. Switching is `wallswitch`
        # (palette.nix): it overwrites `current` and restarts this unit (the
        # pinned hyprctl/hyprpaper pair is protocol-incompatible — no IPC switch).
        xdg.configFile."hypr/hyprpaper.conf".text = ''
          splash = false
          ipc = true

          wallpaper {
              monitor =
              path = ${current}
          }
        '';
      };
}
