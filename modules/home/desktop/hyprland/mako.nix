{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    # notification daemon (Wayland). Colors come from the runtime-generated
    # config (modules/home/palette.nix → ~/.cache/theming/mako.conf) so they
    # follow the wallpaper; without theming mako runs on built-in defaults.
    services.mako.enable = true;

    systemd.user.services.mako = {
      Unit.After = lib.mkIf osConfig.cfg.home.theming.enable [ "matugen-palette.service" ];
      Service.ExecStart = lib.mkIf osConfig.cfg.home.theming.enable (lib.mkForce
        "${pkgs.mako}/bin/mako -c ${config.home.homeDirectory}/.cache/theming/mako.conf");
    };
  };
}
