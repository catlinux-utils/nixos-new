{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.desktop.hyprland.enable = lib.mkEnableOption "Hyprland";

  config = lib.mkIf config.cfg.desktop.hyprland.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base
    cfg.graphics.enable = lib.mkDefault true;
    cfg.audio.enable = lib.mkDefault true;

    # uwsm activates graphical-session.target, where the home-side user units
    # (bar, hypridle, hyprpaper, polkit agent) bind
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # uwsm's module registers the "Hyprland (UWSM)" session itself — do NOT
    # point binPath at the cap_sys_nice wrapper: uwsm aborts when it's missing
    # (live media), leaving GDM in a login loop

    # without the pin, autologin falls back to the non-uwsm `hyprland` entry:
    # graphical-session.target never activates, home-side units never start
    services.displayManager.defaultSession = lib.mkDefault "hyprland-uwsm";

    security.polkit.enable = true;

    # PAM service for the user-side hyprlock locker
    security.pam.services.hyprlock = { };

    # GDM (regreet was buggy, smaller greeters text-only). mkDefault: the
    # installer overrides this — two DMs collide on display-manager.service
    services.displayManager.gdm.enable = lib.mkDefault true;

    # keyring unlock: `login` covers console gettys, gdm-autologin the GDM
    # autologin (on live media the blank password unlocks silently)
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.gdm-autologin.enableGnomeKeyring = true;

    # tray applets export icons by NAME from their own hicolor dirs — they
    # must sit in the system profile for the quickshell bar to resolve them
    environment.systemPackages = [
      pkgs.networkmanagerapplet
      pkgs.blueman
    ];
  };
}
