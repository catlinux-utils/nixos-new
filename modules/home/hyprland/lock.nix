{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # screen locker; the PAM service backing its password prompt is created
    # system-side in modules/nixos/desktop/hyprland.nix
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 5;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = {
          blur_passes = 2;
          blur_size = 8;
        };

        input-field = {
          size = "300, 40";
          outline_thickness = 2;
          placeholder_text = "Password…";
        };
      };
    };
  };
}
