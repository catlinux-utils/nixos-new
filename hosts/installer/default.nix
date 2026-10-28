# Live installer ISO — a full mkHost host (Home Manager session for the
# profile's passwordless `nixos` user) that is built as an IMAGE, not switched
# onto a machine. Build the ISO on a Nix machine:
#
#   nixos-rebuild build-image --flake .#installer --image-variant iso
#
# Flake-aware live environment: upstream's channel.nix and clone-config.nix are
# disabled (they provision a Nixpkgs channel and clone the live config into
# /etc/nixos — both at odds with flake installs); the repo's own always-on
# modules provide Lix, flakes and the pinned registry instead.
{
  lib,
  pkgs,
  ...
}:
let
  nixosModules = pkgs.path + "/nixos/modules";
in
{
  imports = [
    # the upstream installer stack: live-env toolkit (parted, gptfdisk,
    # cryptsetup, vim, …), supported filesystems, passwordless `nixos`/root
    # accounts, passwordless sudo, getty autologin, NetworkManager, sshd,
    # hardware.enableAllHardware, swraid, low-memory tuning
    (nixosModules + "/profiles/base.nix")
    (nixosModules + "/profiles/installation-device.nix")
  ];

  # channel-era mechanisms — the live env installs from flakes
  disabledModules = [
    (nixosModules + "/installer/cd-dvd/channel.nix")
    (nixosModules + "/installer/cd-dvd/clone-config.nix")
  ];

  cfg = {
    # identity — reuse the profile's passwordless `nixos` account: the
    # always-on users.nix merges zsh + wheel into it, Home Manager targets it,
    # and no locked `polishcat` user appears in the live environment
    user = {
      name = "nixos";
      fullName = "Live installer (nixos)";
    };

    # the live environment boots into the repo's Hyprland desktop (GDM
    # autologin below); theming rides the desktop host's wallpaper set
    desktop.hyprland.enable = true;
    home = {
      theming.enable = true;
      theming.wallpapers = [
        ../desktop/wallpapers/dusk.png
        ../desktop/wallpapers/dawn.png
        ../desktop/wallpapers/moss.png
        ../desktop/wallpapers/ember.png
      ];
      hyprland.wallpaper = ../desktop/wallpapers/dusk.png;
    };

    networking = {
      # upstream enables NetworkManager too; this switch adds our module's
      # wait-online un-stall + group wiring
      networkManager.enable = true;
      resolved.enable = true;
    };
  };

  # boot-to-desktop: GDM autologin into the uwsm Hyprland session (mirrors the
  # repo's desktop host pattern where displayManager.enable pulls in the
  # uwsm-managed "Hyprland (UWSM)" session entry). The upstream
  # installation-device.nix enables getty autologin on all VTS; GDM takes
  # tty1, the rest stay as autologin shells. No `cfg.boot` — the ISO variant
  # owns its own bootloader.
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
    autoLogin.enable = true;
    autoLogin.user = "nixos";
  };

  # memory headroom for the live session
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # for `nixos-install --flake` from the live env (nh rides the always-on nh.nix)
  environment.systemPackages = [ pkgs.git ];

  system.stateVersion = "26.05";

  # The `iso` image variant — merged into the base config by the variant
  # machinery (deferredModule). installation-device.nix already resets
  # swapDevices, boot.initrd.luks.devices and fileSystems for media; repeated
  # here as insurance so a future hardware-configuration import can't leak
  # real disk layout onto the CD.
  image.modules.iso = {
    swapDevices = lib.mkImageMediaOverride [ ];
    boot.initrd.luks.devices = lib.mkImageMediaOverride { };

    isoImage = {
      makeEfiBootable = true;
      makeUsbBootable = true;
      # makeBiosBootable defaults to true on x86
      volumeID = "nixos-nixos-new"; # ≤32 chars — stage 1 mounts the CD by it
      configurationName = "nixos-new";
      appendToMenuLabel = " Live";
      squashfsCompression = "zstd -Xcompression-level 6"; # upstream default is 19
      # compressImage = true;                  # whole-ISO zstd → .iso.zst
      # includeSystemBuildDependencies = true; # offline installs (large ISO)
    };
  };
}
