{
  description =
    "Multi-host NixOS flake (desktop, laptop, server, wsl, installer ISO) with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # per-device/per-GPU hardware quirks, imported per host via specialArgs
    # `inputs` (Phase 2 disk/hardware decisions) — tracks master, no release
    # branches; refreshed by the manual flake-update workflow
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # declarative disk partitioning — wired in per host when disk layouts land
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot (dormant, cfg.boot.secureBoot). Deliberately does NOT follow
    # nixpkgs: `pkgs.lzbt` does not exist in 26.05, and lanzaboote's module
    # defaults its package to `self.packages.<system>.lzbt`, built from the
    # nixos-unstable nixpkgs this input carries itself. Officially an
    # nixos-unstable-only module — enable per host only after a real eval on a
    # Nix machine, and only on UEFI hardware.
    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
  };

  outputs =
    # inputs@ binds the whole attrset — modules reach later-added inputs
    # (nixos-wsl, sops-nix, nixos-hardware, disko, lanzaboote) through
    # specialArgs.inputs
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      unstable-overlay = import ./overlays/unstable.nix nixpkgs-unstable;
      mkHost = import ./lib/mkHost.nix {
        inherit lib home-manager inputs unstable-overlay;
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost { hostname = "desktop"; };
        laptop = mkHost { hostname = "laptop"; };
        server = mkHost { hostname = "server"; };
        wsl = mkHost { hostname = "wsl"; };

        # The installer ISO is assembled like a host (mkHost — full Home
        # Manager session for the profile's passwordless `nixos` user) but is
        # an IMAGE, not a switch target: hosts/installer/default.nix adds the
        # `iso` image variant. Built on a Nix machine:
        #   nixos-rebuild build-image --flake .#installer --image-variant iso
        installer = mkHost { hostname = "installer"; };
      };

      overlays.default = unstable-overlay;

      # makes `nix fmt` work
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [
          nixfmt-rfc-style
          nil
        ];
      };
    };
}
