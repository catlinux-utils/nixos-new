{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.cfg.desktop;
in
{
  options.cfg.desktop.enable = lib.mkEnableOption "shared desktop plumbing (fonts, portals, xdg)";

  # the DE modules each flip cfg.desktop.enable; make enabling two a hard error
  assertions = [
    {
      assertion =
        lib.count lib.id [
          config.cfg.desktop.gnome.enable
          config.cfg.desktop.hyprland.enable
          config.cfg.desktop.plasma.enable
        ] <= 1;
      message = "At most one desktop environment (gnome, hyprland, plasma) may be enabled.";
    }
  ];

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
    };

    # gsettings/dconf backend for desktop apps (HM's easyeffects, gtk theming)
    programs.dconf.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "gtk" ];
    };

    # lets DEs (and HM's xdg.userDirs) create/update the standard user dirs
    environment.systemPackages = [ pkgs.xdg-user-dirs ];
  };
}
