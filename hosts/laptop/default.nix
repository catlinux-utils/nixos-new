{
  imports = [
    ./hardware-configuration.nix
    # nixos-hardware quirks — replace with actual model
  ];

  cfg = {
    btrfsMaintenance = {
      enable = true;
      light = true; # portable: monthly scrub, no balance
    };

    # identity
    user = {
      name = "cat";
      fullName = "ThePolishcat";
    };

    # locale
    locale = {
      timeZone = "Europe/Warsaw";
      defaultLocale = "en_US.UTF-8";
      keyboard = "pl";
    };

    # git identity
    git.remote = "git@github.com:catlinux-utils/nixos-new.git";

    home.git = {
      name = "ThePolishcat";
      email = "88453875+PolskiKocurek@users.noreply.github.com";
    };

    # matugen palette from the running wallpaper + waypaper picker
    # (SUPER+SHIFT+W); GNOME owns the wallpaper, theming extracts the palette
    home.theming.enable = true;
    home.theming.wallpapers = [
      ./wallpapers/dusk.png
      ./wallpapers/dawn.png
      ./wallpapers/moss.png
      ./wallpapers/ember.png
    ];

    # features — host matrix: PLAN.md §1.7
    boot.enable = true;
    boot.plymouth.enable = true; # zen kernel undecided — stays off for now
    boot.secureBoot.enable = true; # UKIs via lanzaboote; ESP at /efi
    boot.secureBoot.autoKeys.enable = true;
    networking.networkManager.enable = true;
    networking.resolved.enable = true;
    audio.enable = true;
    graphics.enable = true;
    ssh.enable = true;
    desktop.gnome.enable = true;
    compat.nix-ld.enable = true;
    compat.envfs.enable = true;
    compat.appimage.enable = true;
    kdeconnect.enable = true;

    # standard defaults — PLAN.md §2.1
    firmware.enable = true;
    storage.enable = true;
    bluetooth.enable = true;
    printing.enable = true;
    geolocation.enable = true;
    tailscale.enable = true;
    syncthing.enable = true;

    # laptop candidates — flip when the hardware is known (Phase 2): GNOME
    # already defaults power-profiles-daemon on (cfg.power.* has alternatives);
    # cfg.fprintd.enable, cfg.networking.wifi.* if wanted
  };

  # first-install marker — do NOT bump together with the nixpkgs pin
  system.stateVersion = "26.05";
}
