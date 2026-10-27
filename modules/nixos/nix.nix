{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  nix = {
    # Lix — CLI-compatible with CppNix, so all `nix` commands work unchanged
    package = pkgs.lixPackageSets.latest.lix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        config.cfg.user.name
      ];
    };

    # `nix build nixpkgs#...` resolves to the exact pinned input
    registry.nixpkgs.flake = inputs.nixpkgs;

    # pure-flake hosts carry no channel state; nix-index/comma replaces
    # command-not-found (Phase 4)
    channel.enable = false;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  nixpkgs.config.allowUnfree = true;
}
