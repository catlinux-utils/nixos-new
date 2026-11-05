{
  lib,
  config,
  osConfig,
  ...
}:
{
  config = lib.mkIf (osConfig.cfg.desktop.hyprland.enable && osConfig.cfg.home.hyprland.lock) {
    # screen locker (PAM service system-side). settings = { } so these xdg
    # entries own the file pair: fallback $lock* colors, then an optional
    # matugen overlay (colors only — sections are append-only lists), then the
    # layout; last $var definition wins, missing sources are skipped.
    # Colors: rgb(RRRRRR)/rgba(RRRRRRAA) only — bare #hex does not parse.
    programs.hyprlock.enable = true;

    xdg.configFile."hypr/hyprlock.conf".text = ''
      # fallback palette (hand-tuned family of Theme.qml / the vendored rofi theme)
      $lockFg = rgb(EBEFFE)
      $lockInner = rgba(18161A66)
      $lockOuter = rgb(707F9B)
      $lockCheck = rgb(C7D1FB)
      $lockFail = rgb(F37F97)

      source = ${config.home.homeDirectory}/.cache/theming/hyprlock-colors.conf
      source = ${config.home.homeDirectory}/.config/hypr/hyprlock-base.conf
    '';

    # the styled layout; colors always come from the $lock* variables
    xdg.configFile."hypr/hyprlock-base.conf".text = ''
      general {
          disable_loading_bar = true
          grace = 5
          hide_cursor = true
          no_fade_in = false
      }

      background {
          path = screenshot
          blur_passes = 2
          blur_size = 8
      }

      input-field {
          size = 300, 40
          outline_thickness = 2
          font_color = $lockFg
          inner_color = $lockInner
          outer_color = $lockOuter
          check_color = $lockCheck
          fail_color = $lockFail
          font_family = JetBrainsMono Nerd Font
          placeholder_text = Password…
          fade_on_empty = false
      }
    '';
  };
}
