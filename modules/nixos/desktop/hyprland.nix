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

    security.polkit.enable = true;

    # PAM service for the user-side hyprlock screen locker
    # (modules/home/hyprland/lock.nix) — without it its password prompt
    # cannot authenticate
    security.pam.services.hyprlock = { };

    # libsecret backend for app secrets (VS Code runs with
    # password-store=gnome-libsecret); PAM unlocks the keyring at login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
