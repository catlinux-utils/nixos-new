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
  # scheme-fidelity keeps the wallpaper's own hue at high chroma; the default
  # tonal-spot washes every role into the same gray-blue "nordic" family.
  # --prefer saturation picks the dominant color headlessly (no TTY).
  # The kitty template (templates/kitty-colors.conf.tmpl) deliberately leaves
  # ANSI slots unset so kitty's default vivid palette survives theming.
  matugenFlags = "-m dark -t scheme-fidelity --prefer saturation";
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
  #   gtk-3.0/gtk-4.0 css and the kvantum theme render straight into
  #   ~/.config (paths HM deliberately doesn't manage)
  config =
    lib.mkIf
      (
        osConfig.cfg.desktop.enable
        && osConfig.cfg.home.theming.enable
        && osConfig.cfg.home.hyprland.wallpaper != null
      )
      {
        home.packages = [
          pkgs.unstable.matugen
          pkgs.waypaper
          pkgs.libnotify # notify-send for wallswitch failure reports (mako displays)
          # switch the running wallpaper: copy into the persistent state slot,
          # restart hyprpaper to reload it (the pinned nixpkgs pair is
          # hyprctl/hyprpaper protocol-incompatible — no IPC switch), then
          # regenerate the palette from the copy. Every step logs to
          # ~/.cache/theming/wallswitch.log and failures notify — waypaper
          # spawns this detached, so without the log a failing step would be
          # completely silent. Steps are fail-soft: a hyprpaper restart
          # failure must not eat the palette render (and vice versa).
          (pkgs.writeShellScriptBin "wallswitch" ''
            set -eu
            log="${cacheDir}/wallswitch.log"
            note() { command -v notify-send >/dev/null && notify-send -u critical wallswitch "$1" || true; }
            mkdir -p ${cacheDir} ${stateDir} ${homeDir}/.config/Kvantum/matugen
            if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
              echo "[$(date +%T)] error: usage: wallswitch <image> (got: $*)" >> "$log"
              note "bad arguments: $*"
              exit 1
            fi
            echo "[$(date +%T)] switching to $1" >> "$log"
            cp -- "$1" ${current} || { echo "[$(date +%T)] error: cp failed" >> "$log"; note "copy failed"; exit 1; }
            if systemctl --user restart hyprpaper.service; then
              echo "[$(date +%T)] hyprpaper restarted" >> "$log"
            else
              echo "[$(date +%T)] error: hyprpaper restart failed (rc=$?)" >> "$log"
              note "hyprpaper restart failed — wallpaper may be stale"
            fi
            if ${pkgs.unstable.matugen}/bin/matugen image ${current} ${matugenFlags} >> "$log" 2>&1; then
              echo "[$(date +%T)] palette rendered" >> "$log"
            else
              echo "[$(date +%T)] error: matugen failed (see above in this log)" >> "$log"
              note "palette render failed — check $log"
            fi
          '')
        ];

        # shipped collection for the waypaper picker (read-only store symlinks —
        # picking one copies it, so the originals never need to be writable)
        home.file = lib.listToAttrs (
          map (p: {
            name = "Pictures/Wallpapers/${baseNameOf p}";
            value.source = p;
          }) osConfig.cfg.home.theming.wallpapers
        );

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

          # prompt colors for the catlinux zsh theme (sourced with hardcoded
          # fallbacks when this file is absent)
          [templates.zsh]
          input_path = "${./templates/zsh-colors.conf.tmpl}"
          output_path = "${cacheDir}/zsh-colors.conf"

          [templates.gtk3]
          input_path = "${./templates/gtk.css.tmpl}"
          output_path = "${homeDir}/.config/gtk-3.0/gtk.css"

          [templates.gtk4]
          input_path = "${./templates/gtk.css.tmpl}"
          output_path = "${homeDir}/.config/gtk-4.0/gtk.css"

          # kvantum theme for qt apps (qt5ct/qt6ct select the style; the
          # pointer at ~/.config/Kvantum/kvantum.kvconfig lives in theming.nix)
          [templates.kvantum]
          input_path = "${./templates/kvantum-colors.kvconfig.tmpl}"
          output_path = "${homeDir}/.config/Kvantum/matugen/matugen.kvconfig"
        '';

        # backend = none + post_command: wallswitch is the single switching
        # primitive (hyprpaper + state copy + palette) — waypaper only picks.
        # use_xdg_state must stay OFF: waypaper then reads the folder from THIS
        # config — with it on, read_state() overrides the folder from state.ini,
        # and on first run that file doesn't exist yet, so the picker shows
        # ~/Pictures (empty) instead of ~/Pictures/Wallpapers. waypaper saving
        # picks into this HM-managed file is harmless (activation restores it;
        # nothing in our flow reads waypaper's remembered wallpaper).
        xdg.configFile."waypaper/config.ini".text = ''
          [Settings]
          folder = ${homeDir}/Pictures/Wallpapers
          monitors = All
          backend = none
          post_command = wallswitch $wallpaper
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
              mkdir -p ${stateDir} ${cacheDir} ${homeDir}/.config/Kvantum/matugen
              [ -f ${current} ] || cp ${osConfig.cfg.home.hyprland.wallpaper} ${current}
              # --prefer: matugen 4.x asks interactively which dominant color to
              # use when an image yields several — a systemd service has no TTY,
              # so without it the seed dies with "not a terminal"
              exec ${pkgs.unstable.matugen}/bin/matugen image ${current} ${matugenFlags}
            '';
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # the bar reads the generated palette; start it after the first render
        systemd.user.services.quickshell.Unit.After = [ "matugen-palette.service" ];
      };
}
