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
  # scheme-fidelity keeps the wallpaper's hue (default tonal-spot washes it
  # gray-blue); --prefer saturation avoids the interactive prompt (no TTY).
  # The kitty template leaves ANSI slots unset so kitty's vivid defaults survive.
  matugenFlags = "-m dark -t scheme-fidelity --prefer saturation";
in
{
  # Runtime theming: matugen renders the vendored templates from the running
  # wallpaper (waypaper picks). Generated files live outside HM management —
  # store symlinks can't be overwritten at runtime: state/theming/current,
  # cache/theming/*, plus gtk css/kvantum into ~/.config paths HM doesn't own.
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
          # wallswitch: copy to state slot, restart hyprpaper (no IPC switch —
          # protocol-incompatible pins), re-render palette. Logs + notify-send
          # (waypaper spawns detached); fail-soft per step.
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
            # -f/chmod: cp inherits the store path's r--r--r-- mode — keep the copy writable
            cp -f -- "$1" ${current} || { echo "[$(date +%T)] error: cp failed" >> "$log"; note "copy failed"; exit 1; }
            chmod 600 ${current}
            # retry: a restart races a still-in-flight previous stop job (systemd rejects it)
            ok=""
            for attempt in 1 2 3 4 5; do
              if systemctl --user restart hyprpaper.service; then
                ok=1
                break
              fi
              echo "[$(date +%T)] restart attempt $attempt failed, retrying" >> "$log"
              sleep 1
            done
            if [ -n "$ok" ]; then
              echo "[$(date +%T)] hyprpaper restarted" >> "$log"
            else
              echo "[$(date +%T)] error: hyprpaper restart failed after 5 attempts" >> "$log"
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

        # shipped wallpapers for the waypaper picker (read-only store symlinks; picking copies)
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

          # zsh prompt colors (catlinux theme sources them with hardcoded fallbacks)
          [templates.zsh]
          input_path = "${./templates/zsh-colors.conf.tmpl}"
          output_path = "${cacheDir}/zsh-colors.conf"

          [templates.gtk3]
          input_path = "${./templates/gtk.css.tmpl}"
          output_path = "${homeDir}/.config/gtk-3.0/gtk.css"

          [templates.gtk4]
          input_path = "${./templates/gtk.css.tmpl}"
          output_path = "${homeDir}/.config/gtk-4.0/gtk.css"

          # kvantum for qt apps (qt5ct/qt6ct pick the style; kvconfig pointer in theming.nix)
          [templates.kvantum]
          input_path = "${./templates/kvantum-colors.kvconfig.tmpl}"
          output_path = "${homeDir}/.config/Kvantum/matugen/matugen.kvconfig"
        '';

        # backend = none + post_command: wallswitch is the only switcher,
        # waypaper just picks. use_xdg_state must stay OFF (read_state()
        # overrides the folder from a nonexistent state.ini → empty picker).
        # waypaper rewriting this HM-managed file is harmless.
        xdg.configFile."waypaper/config.ini".text = ''
          [Settings]
          folder = ${homeDir}/Pictures/Wallpapers
          monitors = All
          backend = none
          post_command = wallswitch $wallpaper
          zen_mode = true
        '';

        # login oneshot: copies the default wallpaper to the state slot exactly
        # once, then the state copy is authoritative (deleting it re-seeds)
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
              # install -m, not cp: cp would reproduce the store path's
              # r--r--r-- mode, making every later wallswitch cp fail
              [ -f ${current} ] || install -m 600 ${osConfig.cfg.home.hyprland.wallpaper} ${current}
              # --prefer: matugen 4.x asks interactively when an image yields
              # several dominant colors — no TTY here, it would die
              exec ${pkgs.unstable.matugen}/bin/matugen image ${current} ${matugenFlags}
            '';
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # the bar reads the generated palette; quickshell.service only exists
        # on hyprland (quickshell.nix)
        systemd.user.services.quickshell.Unit.After = lib.mkIf osConfig.cfg.desktop.hyprland.enable [
          "matugen-palette.service"
        ];
      };
}
