# Slim variant of `desktop` for the same machine — the full Hyprland
# workstation profile with the heavy/peripheral features dropped: no gaming
# stack (+ its 32-bit GL closure), no ollama (the multi-GB ROCm build), no
# printing/scanning, kdeconnect, geolocation or tailscale. Home apps stay
# untouched (vscode/mpv/pinta/yt-dlp/prefetchTools all on). Shares the disk
# layout, so the placeholder hardware-configuration matches desktop's.
{
  imports = [
    ./hardware-configuration.nix
    # nixos-hardware quirks — replace with actual model(s), e.g.
    # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-carbon-gen9
    # inputs.nixos-hardware.nixosModules.asus-rog-zephyrus-g14-2022
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

    # theming: matugen palette from the running wallpaper + waypaper picker
    # (SUPER+SHIFT+W). The vendored set ships to ~/Pictures/Wallpapers;
    # `wallpaper` is the install-time default — it seeds
    # ~/.local/state/theming/current exactly once and is never re-applied
    # afterwards. Replace the files to change the collection.
    home.theming.enable = true;
    home.theming.wallpapers = [
      ../desktop/wallpapers/dusk.png
      ../desktop/wallpapers/dawn.png
      ../desktop/wallpapers/moss.png
      ../desktop/wallpapers/ember.png
    ];
    home.hyprland.wallpaper = ../desktop/wallpapers/dusk.png;

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
    desktop.hyprland.enable = true;
    compat.nix-ld.enable = true;
    compat.envfs.enable = true;
    compat.appimage.enable = true;

    # standard defaults — PLAN.md §2.1
    firmware.enable = true;
    storage.enable = true;
    bluetooth.enable = true;
  };

  # first-install marker — do NOT bump together with the nixpkgs pin
  system.stateVersion = "26.05";
}
