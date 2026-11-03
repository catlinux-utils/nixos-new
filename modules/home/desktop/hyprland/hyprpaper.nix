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
    lib.mkIf (osConfig.cfg.desktop.hyprland.enable && osConfig.cfg.home.hyprland.wallpaper != null)
      {
        services.hyprpaper.enable = true;

        # HM's hyprpaper module only creates the systemd unit (store-path
        # ExecStart) — the binary itself never lands on the user PATH, and
        # waypaper's startup check `shutil.which("hyprpaper")` then fails and
        # the picker exits with the "no wallpaper backends" dialog
        home.packages = [ config.services.hyprpaper.package ];

        # hyprpaper 0.8.x dropped the old `preload`/`wallpaper=mon,path` lines
        # (its config is hyprlang now: wallpaper entries keyed by monitor, an
        # empty monitor matching every output). HM's settings renderer targets
        # the old syntax, so the conf is written verbatim here — settings stay
        # empty so the HM module generates nothing.
        # Dynamic switching is `wallswitch` (palette.nix): it overwrites `current`
        # and restarts this unit — the pinned nixpkgs pair (hyprctl 0.55 + hyprpaper
        # 0.8) is protocol-incompatible, so hyprctl hyprpaper requests can't do it.
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
