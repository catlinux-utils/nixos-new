# Phase 1.5 — WSL dev host: once the distro is bootstrapped (`wsl --import`,
# see PLAN.md), this machine validates the flake locally from Windows.
# Platform wiring — never touch boot.loader* here: WSL owns boot, networking
# is Windows-side, WSLg provides graphics/audio.
{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.wsl ];

  system.stateVersion = "26.05"; # first-install marker

  wsl = {
    enable = true;
    # must agree with the user modules/nixos/users.nix creates
    defaultUser = config.cfg.user.name;
  };

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

    # where this flake lives on this machine (drives nh) — must stay on the
    # WSL Linux filesystem; /mnt/c is too slow for nix
    nh.flakeDir = /home/cat/nixos;

    # git identity
    home.git = {
      name = "ThePolishcat";
      email = "88453875+PolskiKocurek@users.noreply.github.com";
    };

    # features — dev host: boot/networking/audio/graphics stay off (WSL and
    # the Windows side own them); no firewall — WSL traffic is filtered on
    # the Windows side and nftables here would only block Windows→WSL access.
    # Passwordless sudo comes from NixOS-WSL (wheelNeedsPassword = false), so
    # no initialHashedPassword is needed before the first `nh os switch`.
    networking.firewall.enable = false;
    compat.nix-ld.enable = true; # vscode-server (VS Code WSL remote)
  };
}
