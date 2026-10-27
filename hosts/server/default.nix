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

    # features — headless: no desktop, no audio/graphics/NM; compat is nix-ld
    # only (vscode-server) — host matrix: PLAN.md §1.7
    boot.enable = true;
    ssh.enable = true;
    virtualisation.docker.enable = true;
    compat.nix-ld.enable = true;
  };
}
