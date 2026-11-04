# Live installer ISO — a full mkHost host (Home Manager session for the
# profile's passwordless `nixos` user) that is built as an IMAGE, not switched
# onto a machine. Build the ISO on a Nix machine:
#
#   nixos-rebuild build-image --flake .#installer --image-variant iso
#
# NOTE: the ISO embeds the COMMITTED repo tree (copied to ~/github/nixos in the
# live session) — commit/push before building or the image ships a stale tree.
#
# Flake-aware live environment: upstream's channel.nix and clone-config.nix are
# disabled (they provision a Nixpkgs channel and clone the live config into
# /etc/nixos — both at odds with flake installs); the repo's own always-on
# modules provide Lix, flakes and the pinned registry instead.
{
  lib,
  config,
  pkgs,
  inputs,
  self,
  ...
}:
let
  # The pinned nixpkgs source. This must come from inputs (specialArgs), NOT
  # from the `pkgs` module arg: imports and disabledModules resolve before the
  # module system has a config, and `pkgs` is only reachable through
  # config._module.args — forcing it here is an infinite recursion.
  nixosModules = inputs.nixpkgs + "/nixos/modules";

  # The repo's own source, embedded in the live environment. `self` is the
  # git-cleaned flake tree as a store path — no `.git`, so it lands as a
  # plain (path-)flake dir; good for `nixos-install --flake`, not for commits.
  repoSrc = self;
  repoDest = "/home/${config.cfg.user.name}/github/nixos";
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
    # and no locked `cat` user appears in the live environment
    user = {
      name = "nixos";
      fullName = "Live installer (nixos)";
      # mirrors upstream installation-device's "" (it wins anyway) and gates
      # the promptless keyring seed (modules/home/keyring.nix)
      initialHashedPassword = "";
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

      # no screen lock: the live `nixos` user's empty password can't unlock
      # hyprlock (no nullok on its PAM service), so a 5-min idle would strand
      # the session behind an unrecoverable lock screen — and live media has
      # nothing to protect
      hyprland.lock = false;

      # slim live env: editor, media player, image editor, yt-dlp (deno) and
      # the nix prefetch tools (nix-*-dev closure) are dead weight here;
      # browser, file manager and gparted stay for real install work
      vscode.enable = false;
      mpv.enable = false;
      pinta.enable = false;
      ytDlp.enable = false;
      prefetchTools.enable = false;
    };

    networking = {
      # upstream enables NetworkManager too; this switch adds our module's
      # wait-online un-stall + group wiring
      networkManager.enable = true;
      resolved.enable = true;
    };
  };

  # autostart: open the repo's install guide when the live session starts —
  # a systemd user service bound to graphical-session.target (activated by
  # uwsm), the same channel as the polkit agent. kitty runs as the service's
  # foreground main PID (no --detach: the detached child's failure is
  # invisible, exit 0 is all the journal ever sees) and ExecStartPre waits
  # for the wayland socket — target activation can race the compositor's
  # first socket setup. bat pages the guide read-only (same viewer as the
  # shell's cat); kitty/bat via HM (useGlobalPkgs: same pkgs here), absolute
  # store paths because a bare PATH in a user unit isn't guaranteed.
  home-manager.users.${config.cfg.user.name}.systemd.user.services.installer-guide = {
    Unit = {
      Description = "Open the install guide (~/github/nixos/docs/INSTALL.md)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre =
        # block up to ~15s for WAYLAND_DISPLAY and its socket to exist
        # (dollar-signs doubled: systemd expands $VAR itself at command
        # start, these must be expanded by bash per loop iteration)
        "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 150); do [ -n \"$$WAYLAND_DISPLAY\" ] && [ -S \"$$XDG_RUNTIME_DIR/$$WAYLAND_DISPLAY\" ] && exit 0; sleep 0.1; done; echo \"no wayland socket ($$WAYLAND_DISPLAY in $$XDG_RUNTIME_DIR)\" >&2; exit 1'";
      ExecStart = "${pkgs.kitty}/bin/kitty ${pkgs.bat}/bin/bat %h/github/nixos/docs/INSTALL.md";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # boot-to-desktop: greetd autologins the live user straight into the
  # uwsm Hyprland session (same UX the GDM block provided, without GDM's
  # greeter dragging the whole GNOME/ibus/speech stack — ~0.7-1G of closure).
  # The uwsm command mirrors the hyprland-uwsm session entry's Exec
  # (programs/wayland/uwsm.nix: `uwsm start -F -- <binPath>`). No `cfg.boot` —
  # the ISO variant owns its own bootloader.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${lib.getExe pkgs.uwsm} start -F -- /run/current-system/sw/bin/Hyprland";
        user = config.cfg.user.name;
      };
      default_session = {
        # shown only on logout
        command = "${lib.getExe pkgs.greetd.tuigreet} --time --asterisks";
        user = "greeter";
      };
    };
  };
  # keyring unlock at greetd PAM is automatic: the greetd module defaults
  # enableGnomeKeyring on when services.gnome.gnome-keyring is enabled

  # fonts: drop the CJK sets (pl-locale installer) and the ~220 MiB full Nerd
  # Font — plain JetBrains Mono + symbols-only cover the same glyphs via
  # fontconfig (the bar's icon font falls back through fontconfig by design,
  # see quickshell/shell.qml). The alias keeps every "JetBrainsMono Nerd
  # Font" request (kitty, hyprlock, the bar) resolving.
  fonts.packages = lib.mkForce (
    with pkgs;
    [
      jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-color-emoji
    ]
  );
  fonts.fontconfig.confPackages = [
    (pkgs.writeTextDir "etc/fonts/conf.d/69-jetbrainsmono-nerd-alias.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test qual="any" name="family"><string>JetBrainsMono Nerd Font</string></test>
          <edit name="family" mode="prepend" binding="same"><string>JetBrains Mono</string></edit>
        </match>
      </fontconfig>
    '')
  ];

  # UEFI-only ISO: no BIOS (grub) boot entry needed on any target machine
  # (~60 MiB); ModemManager rides NetworkManager's mkDefault — no WWAN on
  # install targets (~70 MiB with libqmi/mbim)
  networking.modemmanager.enable = false;

  # Image-only host: `nix flake check` (and any non-image eval) sees this BASE
  # config, while the `iso` variant (iso-image.nix) owns boot and mounts. 26.05
  # defaults grub on for non-containers and stage-1 asserts a root fs — mirror
  # the variant's media overrides here so the base stays assert-clean; the
  # variant re-wins them at the same priority with the real live-ISO layout.
  boot.loader.grub.enable = lib.mkImageMediaOverride false;
  fileSystems."/" = lib.mkImageMediaOverride {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  # memory headroom for the live session
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # for `nixos-install --flake` from the live env (nh rides the always-on nh.nix)
  environment.systemPackages = [ pkgs.git ];

  # Drop the full repo into the live session at ~/github/nixos. /home is tmpfs
  # on the ISO, so the copy runs at activation (after users/groups exist);
  # referencing the store path here also pulls the source into the ISO's
  # closure, making offline `nixos-install --flake ~/github/nixos#<host>` work.
  # Writable (a store-path symlink couldn't be edited) and re-laid fresh every
  # boot, so image updates always ship the current tree.
  system.activationScripts.installerRepo = lib.stringAfter [ "users" "groups" ] ''
    mkdir -p /home/${config.cfg.user.name}/github
    rm -rf ${repoDest}
    cp -R ${repoSrc} ${repoDest}
    chown -R ${config.cfg.user.name}:users ${repoDest}
    chmod -R u+w ${repoDest}
  '';

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
      makeBiosBootable = false; # UEFI-only — drops grub from the closure
      volumeID = "nixos-nixos-new"; # ≤32 chars — stage 1 mounts the CD by it
      configurationName = "nixos-new";
      appendToMenuLabel = " Live";
      squashfsCompression = "zstd -Xcompression-level 6"; # upstream default is 19
      # compressImage = true;                  # whole-ISO zstd → .iso.zst
      # includeSystemBuildDependencies = true; # offline installs (large ISO)
    };
  };
}
