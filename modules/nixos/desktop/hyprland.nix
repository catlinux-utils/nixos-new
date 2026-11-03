{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.hyprland.enable = lib.mkEnableOption "Hyprland";

  config = lib.mkIf config.cfg.desktop.hyprland.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base
    cfg.graphics.enable = lib.mkDefault true;
    cfg.audio.enable = lib.mkDefault true;

    # session runs through uwsm: it activates graphical-session.target, which
    # is where the home-side user units (the bar, hypridle, hyprpaper, the
    # polkit agent) bind
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # uwsm's module already registers a "Hyprland (UWSM)" display-manager
    # session by default (binPath /run/current-system/sw/bin/Hyprland) — no
    # override wanted: pointing it at the cap_sys_nice security wrapper made
    # uwsm abort the whole session ("Path ... is not readable") whenever the
    # wrapper is missing, e.g. on live media, leaving GDM in a login loop

    # pin the session: without it autologinSession falls back to the first
    # entry alphabetically — the plain `hyprland` one, which is not
    # uwsm-managed, so graphical-session.target never activates and the
    # home-side units (bar, idle, paper, agent) never start
    services.displayManager.defaultSession = lib.mkDefault "hyprland-uwsm";

    security.polkit.enable = true;

    # PAM service for the user-side hyprlock screen locker
    # (modules/home/hyprland/lock.nix) — without it its password prompt
    # cannot authenticate
    security.pam.services.hyprlock = { };

    # gnome-keyring unlock at GDM autologin too (the `login` stack only covers
    # console gettys): on live media the login password is blank, so the
    # keyring's blank-password keyring unlocks silently; on real hosts the
    # keyring password equals the login password and still unlocks without
    # prompting — nothing is ever stored in plaintext config
    security.pam.services.gdm-autologin.enableGnomeKeyring = true;

    # libsecret backend for app secrets (VS Code runs with
    # password-store=gnome-libsecret); PAM unlocks the keyring at login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
