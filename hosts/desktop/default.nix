{
  imports = [ ./hardware-configuration.nix ];

  cfg = {
    # identity
    user = {
      name = "polishcat";
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
    # (SUPER+SHIFT+W). The vendored set ships to ~/Pictures/Wallpapers;
    # `wallpaper` is the install-time default — it seeds
    # ~/.local/state/theming/current exactly once and is never re-applied
    # afterwards. Replace the files to change the collection.
    home.theming.enable = true;
    home.theming.wallpapers = [
      ./wallpapers/dusk.png
      ./wallpapers/dawn.png
      ./wallpapers/moss.png
      ./wallpapers/ember.png
    ];
    home.hyprland.wallpaper = ./wallpapers/dusk.png;

    # features — host matrix: PLAN.md §1.7
    boot.enable = true;
    boot.zenKernel.enable = true;
    boot.plymouth.enable = true;
    networking.networkManager.enable = true;
    networking.resolved.enable = true;
    audio.enable = true;
    graphics.enable = true;
    ssh.enable = true;
    gaming.enable = true;
    desktop.hyprland.enable = true;
    compat.nix-ld.enable = true;
    compat.envfs.enable = true;
    compat.appimage.enable = true;
    ollama.enable = true;
    ollama.rocmGfx = "10.3.0";
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
