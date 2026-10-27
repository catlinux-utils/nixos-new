{
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
  };

  outputs =
    # inputs@ binds the whole attrset — modules reach later-added inputs
    # (nixos-wsl, nixos-hardware, sops-nix) through specialArgs.inputs
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
