{
  imports = [
    ./hardware-configuration.nix
    # nixos-hardware quirks — replace with actual model(s)
  ];

  cfg = {
    btrfsMaintenance.enable = true;

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
    # (SUPER+SHIFT+W); `wallpaper` is the install-time default — seeds
    # ~/.local/state/theming/current exactly once, never re-applied after
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
    boot.secureBoot.enable = true; # UKIs via lanzaboote; ESP at /efi
    boot.secureBoot.autoKeys.enable = true;
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
  };

  # first-install marker — do NOT bump together with the nixpkgs pin
  system.stateVersion = "26.05";
}
