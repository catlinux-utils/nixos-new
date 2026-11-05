{
  imports = [
    ./hardware-configuration.nix
    # nixos-hardware quirks — replace with actual model
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

    # features — headless: no desktop, no audio/graphics/NM; compat is nix-ld
    # only (vscode-server)
    boot.enable = true;
    boot.secureBoot.enable = true; # UKIs via lanzaboote; ESP at /efi
    boot.secureBoot.autoKeys.enable = true;
    ssh.enable = true;
    home.tmux.enable = true; # ssh sessions survive disconnects
    networking.resolved.enable = true;
    # legacy fleet ran podman — flip to virtualisation.podman.enable to switch
    virtualisation.docker.enable = true;
    compat.nix-ld.enable = true;

    # standard defaults — PLAN.md §2.1 (headless subset)
    firmware.enable = true;
    storage.enable = true;
    tailscale.enable = true;
    syncthing.enable = true;

    # server hardening — PLAN.md §2.1
    hardening.enable = true;
    fail2ban.enable = true;
    # monitoring is opt-in per service (Tailscale/localhost reach):
    # cfg.monitoring.nodeExporter/.netdata/.uptimeKuma.enable
  };

  # first-install marker — do NOT bump together with the nixpkgs pin
  system.stateVersion = "26.05";
}
