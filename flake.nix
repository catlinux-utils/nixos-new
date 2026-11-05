{
  description = "Multi-host NixOS flake (desktop, desktop-lite, laptop, server, wsl, installer ISO) with Home Manager";

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
    # `inputs` — tracks master, refreshed by the manual flake-update workflow
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Secure Boot (dormant, cfg.boot.secureBoot). Deliberately does NOT follow
    # nixpkgs: `pkgs.lzbt` doesn't exist in 26.05 — the module defaults to its
    # own lzbt built from the nixos-unstable nixpkgs carried here.
    # nixos-unstable-only: eval on a Nix machine before enabling (UEFI only).
    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
  };

  outputs =
    # inputs@ binds the whole attrset — modules reach later-added inputs via
    # specialArgs.inputs
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      unstable-overlay = import ./overlays/unstable.nix nixpkgs-unstable;
      mkHost = import ./lib/mkHost.nix {
        inherit
          lib
          self
          home-manager
          inputs
          unstable-overlay
          ;
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost { hostname = "desktop"; };

        # Same machine as `desktop`, slim: full Hyprland workstation minus
        # gaming/ollama/printing/kdeconnect/geolocation/tailscale —
        # deploy with `nh os switch --flake .#desktop-lite`
        desktop-lite = mkHost { hostname = "desktop-lite"; };

        laptop = mkHost { hostname = "laptop"; };
        server = mkHost { hostname = "server"; };
        wsl = mkHost { hostname = "wsl"; };

        # The installer ISO: assembled like a host (mkHost, full HM session)
        # but an IMAGE, not a switch target — hosts/installer adds the `iso`
        # variant; build with --image-variant iso (see that file)
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
