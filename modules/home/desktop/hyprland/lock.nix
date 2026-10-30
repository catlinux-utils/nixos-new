{
  lib,
  config,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # screen locker; the PAM service backing its password prompt is created
    # system-side in modules/nixos/desktop/hyprland.nix
    #
    # HM's own config generation is left empty (settings = { }) — no
    # hyprlock.conf is written by it, so these two xdg entries own the file
    # pair. The entry point is a dispatcher: hardcoded fallback $lock* color
    # variables, then an optional matugen overlay that redefines them (colors
    # only — hyprlock's sections are append-only lists and a runtime
    # re-declaration would fan out duplicate widgets), then the layout file
    # sourced last. hyprlang expands $var at line parse time and keeps the
    # last definition, so the overlay wins when present; a missing source file
    # is only logged and skipped, keeping the fallbacks. Colors use hyprlock's
    # rgb(RRRRRR)/rgba(RRRRRRAA) hex forms — bare #hex does not parse.
    programs.hyprlock.enable = true;

    xdg.configFile."hypr/hyprlock.conf".text = ''
      # fallback palette (hand-tuned family of Theme.qml / the vendored rofi
      # theme); the matugen overlay below redefines these when theming is on
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
