# Live installer ISO — a full mkHost host built as an IMAGE, not switched:
#   nixos-rebuild build-image --flake .#installer --image-variant iso
# Embeds the COMMITTED repo tree (~/github/nixos) — commit/push before
# building. Flake-aware: upstream's channel.nix + clone-config.nix disabled.
{
  lib,
  config,
  pkgs,
  inputs,
  self,
  ...
}:
let
  # From inputs, NOT the `pkgs` module arg: imports/disabledModules resolve
  # before config exists — forcing `pkgs` here is infinite recursion.
  nixosModules = inputs.nixpkgs + "/nixos/modules";

  # `self`: git-cleaned flake tree (store path, no .git) — for nixos-install, not commits
  repoSrc = self;
  repoDest = "/home/${config.cfg.user.name}/github/nixos";
in
{
  imports = [
    # upstream installer stack: live-env toolkit, passwordless nixos/root + sudo, autologin, NM, sshd
    (nixosModules + "/profiles/base.nix")
    (nixosModules + "/profiles/installation-device.nix")
  ];

  # channel-era mechanisms — the live env installs from flakes
  disabledModules = [
    (nixosModules + "/installer/cd-dvd/channel.nix")
    (nixosModules + "/installer/cd-dvd/clone-config.nix")
  ];

  cfg = {
    # reuses the profile's passwordless `nixos` account (users.nix merges zsh + wheel, HM targets it)
    user = {
      name = "nixos";
      fullName = "Live installer (nixos)";
      # upstream sets initialHashedPassword = ""; null avoids a second password option (eval warning)
      initialPassword = null;
    };

    # boots into the repo's Hyprland desktop (greetd autologin below); wallpapers from the desktop host
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

      # no screen lock: the empty-password `nixos` user can't unlock hyprlock (no PAM nullok)
      hyprland.lock = false;

      # slim live env: editor/media/image/yt-dlp/prefetch tools off; browser, file manager, gparted stay
      vscode.enable = false;
      mpv.enable = false;
      pinta.enable = false;
      ytDlp.enable = false;
      prefetchTools.enable = false;
    };

    networking = {
      # upstream enables NM too; this adds our wait-online un-stall + group wiring
      networkManager.enable = true;
      resolved.enable = true;
      # the default-on firewall would block upstream's live-media sshd — same reason wsl disables it
      firewall.enable = false;
    };
  };

  # autostart: open the install guide (graphical-session.target). kitty stays
  # foreground so failures reach the journal; ExecStartPre waits for the
  # wayland socket (activation races the compositor)
  home-manager.users.${config.cfg.user.name}.systemd.user.services.installer-guide = {
    Unit = {
      Description = "Open the install guide (~/github/nixos/docs/INSTALL.md)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre =
        # ~15s wait for the wayland socket ($$ = literal for systemd)
        "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 150); do [ -n \"$$WAYLAND_DISPLAY\" ] && [ -S \"$$XDG_RUNTIME_DIR/$$WAYLAND_DISPLAY\" ] && exit 0; sleep 0.1; done; echo \"no wayland socket ($$WAYLAND_DISPLAY in $$XDG_RUNTIME_DIR)\" >&2; exit 1'";
      ExecStart = "${pkgs.kitty}/bin/kitty ${pkgs.bat}/bin/bat %h/github/nixos/docs/INSTALL.md";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # greetd autologin into the uwsm Hyprland session (no `cfg.boot` — the ISO
  # variant owns the bootloader); GDM off — two DMs collide on
  # display-manager.service
  services.displayManager.gdm.enable = false;
  services.greetd = {
    enable = true;
    # keep boot console noise off the text greeter (shown on logout)
    useTextGreeter = true;
    settings = {
      initial_session = {
        # mirrors Hyprland's own hyprland-uwsm.desktop Exec — a bare-binary launch trips a debugging warning
        command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
        user = config.cfg.user.name;
      };
      default_session = {
        # shown only on logout
        command = "${lib.getExe pkgs.tuigreet} --time --asterisks";
        user = "greeter";
      };
    };
  };
  # greetd has no keyring toggle — its PAM substacks `login`, whose
  # enableGnomeKeyring is set by desktop/hyprland.nix (deleting it breaks keyring here)

  # drop CJK + ~220 MiB Nerd Font — JetBrains Mono + symbols-only cover the glyphs
  # via fontconfig; the alias keeps "JetBrainsMono Nerd Font" requests resolving
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

  # ModemManager rides NM's mkDefault — no WWAN on install targets (~70 MiB)
  networking.modemmanager.enable = false;

  # base stays assert-clean for non-image eval (grub default, stage-1 root fs);
  # the iso variant re-wins these at the same priority
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

  # repo copy at ~/github/nixos: in the ISO closure (offline nixos-install),
  # fresh every boot (/home is tmpfs) but guarded — activation runs on every
  # `nh os switch` and must not clobber in-session edits
  system.activationScripts.installerRepo = lib.stringAfter [ "users" "groups" ] ''
    if [ ! -e ${repoDest} ]; then
      mkdir -p /home/${config.cfg.user.name}/github
      cp -R ${repoSrc} ${repoDest}
      chown -R ${config.cfg.user.name}:users ${repoDest}
      chmod -R u+w ${repoDest}
    fi
  '';

  system.stateVersion = "26.05";

  # `iso` image variant; the media resets are insurance against a future
  # hardware-configuration import leaking real disk layout onto the CD
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
