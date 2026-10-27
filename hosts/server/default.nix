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

    # features — headless: no desktop, no audio/graphics/NM; compat is nix-ld
    # only (vscode-server) — host matrix: PLAN.md §1.7
    boot.enable = true;
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
  };
}
