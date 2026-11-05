{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma 6 (SDDM)";

  config = lib.mkIf config.cfg.desktop.plasma.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base
    # mirror hyprland.nix's implications — a DE without GPU/audio base is
    # a half-install
    cfg.graphics.enable = lib.mkDefault true;
    cfg.audio.enable = lib.mkDefault true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;
  };
}
