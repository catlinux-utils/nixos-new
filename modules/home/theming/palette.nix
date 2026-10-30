{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  cacheDir = "${homeDir}/.cache/theming";
  stateDir = "${homeDir}/.local/state/theming";
  current = "${stateDir}/current";
in
{
  # Runtime theming: matugen extracts a Material-You palette from the running
  # wallpaper and renders the vendored templates under ./templates/; waypaper
  # is the wallpaper picker. Everything user-writable lives outside HM's
  # managed paths (store symlinks cannot be overwritten at runtime):
  #   ~/.local/state/theming/current  — the running wallpaper (copied, persists
  #                                     across reboots; the authoritative file)
  #   ~/.cache/theming/               — generated palette, kitty, mako, rofi,
  #                                     hyprlock outputs
  config = lib.mkIf
    (
      osConfig.cfg.desktop.enable
      && osConfig.cfg.home.theming.enable
      && osConfig.cfg.home.hyprland.wallpaper != null
    )
    {
      home.packages = [
        pkgs.matugen
        pkgs.waypaper
        (pkgs.writeShellScriptBin "wallswitch" ''
          # switch the running wallpaper: copy into the persistent state slot,
          # point hyprpaper at it, regenerate the palette from the copy
          set -eu
          [ "$#" -eq 1 ] || { echo "usage: wallswitch <image>" >&2; exit 1; }
          src=$1
          [ -f "$src" ] || { echo "wallswitch: no such file: $src" >&2; exit 1; }
          mkdir -p ${stateDir}
          cp -- "$src" ${current}
          if command -v hyprctl >/dev/null 2>&1; then
            hyprctl hyprpaper unload all >/dev/null 2>&1 || true
            hyprctl hyprpaper preload ${current} >/dev/null
            hyprctl hyprpaper wallpaper ",${current}" >/dev/null
          fi
          ${pkgs.matugen}/bin/matugen image ${current} -m dark
        '')
      ];

      # shipped collection for the waypaper picker (read-only store symlinks —
      # picking one copies it, so the originals never need to be writable)
      home.file = lib.listToAttrs (map
        (p: {
          name = "Pictures/Wallpapers/${baseNameOf p}";
          value.source = p;
        })
        osConfig.cfg.home.theming.wallpapers);

      xdg.configFile."matugen/config.toml".text = ''
        [config]
        version_check = false

        [templates.palette-json]
        input_path = "${./templates/palette.json.tmpl}"
        output_path = "${cacheDir}/palette.json"

        [templates.kitty]
        input_path = "${./templates/kitty-colors.conf.tmpl}"
        output_path = "${cacheDir}/kitty-colors.conf"
        post_hook = "pkill -USR1 kitty || true"

        [templates.mako]
        input_path = "${./templates/mako.conf.tmpl}"
        output_path = "${cacheDir}/mako.conf"
        post_hook = "makoctl reload || true"

        [templates.rofi]
        input_path = "${./templates/rofi.rasi.tmpl}"
        output_path = "${cacheDir}/rofi.rasi"

        [templates.hyprlock]
        input_path = "${./templates/hyprlock-colors.conf.tmpl}"
        output_path = "${cacheDir}/hyprlock-colors.conf"

        [templates.gtk3]
        input_path = "${./templates/gtk.css.tmpl}"
        output_path = "${homeDir}/.config/gtk-3.0/gtk.css"

        [templates.gtk4]
        input_path = "${./templates/gtk.css.tmpl}"
        output_path = "${homeDir}/.config/gtk-4.0/gtk.css"
      '';

      # backend = none + post_command: wallswitch is the single switching
      # primitive (hyprpaper + state copy + palette). use_xdg_state keeps
      # waypaper's runtime state in state.ini — this config.ini is HM-managed.
      xdg.configFile."waypaper/config.ini".text = ''
        [Settings]
        folder = ${homeDir}/Pictures/Wallpapers
        monitors = All
        backend = none
        post_command = wallswitch $wallpaper
        use_xdg_state = true
      '';

      # login oneshot: install-time seed — the default wallpaper is copied to
      # the state slot exactly once, then the state copy is authoritative and
      # no code path re-applies the default (deleting the state file re-seeds)
      systemd.user.services.matugen-palette = {
        Unit = {
          Description = "matugen palette from the running wallpaper";
          Before = [ "hyprpaper.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "matugen-palette-start" ''
            mkdir -p ${stateDir} ${cacheDir}
            [ -f ${current} ] || cp ${osConfig.cfg.home.hyprland.wallpaper} ${current}
            exec ${pkgs.matugen}/bin/matugen image ${current} -m dark
          '';
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # the bar reads the generated palette; start it after the first render
      systemd.user.services.quickshell.Unit.After = [ "matugen-palette.service" ];
    };
}
