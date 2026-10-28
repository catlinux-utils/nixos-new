{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    # nixos-hardware quirks — replace with actual model, e.g.
    # inputs.nixos-hardware.nixosModules.framework-laptop-13-intel-12th-gen
    # inputs.nixos-hardware.nixosModules.dell-xps-13-9310
  ];

  cfg = {
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

    # where this flake lives on this machine (drives nh)
    nh.flakeDir = /etc/nixos; # TODO: real repo path

    # git identity
    home.git = {
      name = "ThePolishcat";
      email = "88453875+PolskiKocurek@users.noreply.github.com";
    };

    # theming: matugen palette from the running wallpaper + waypaper picker
    # (SUPER+SHIFT+W). The vendored set ships to ~/Pictures/Wallpapers.
    # GNOME manages its own wallpaper; theming extracts palette from whatever
    # is set and recolors GTK/Qt/bar/mako/kitty/hyprlock.
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
  };
}
