# Curried: flake.nix applies `import ./overlays/unstable.nix nixpkgs-unstable`.
# Gives every module (and home-manager module, via useGlobalPkgs) `pkgs.unstable.<pkg>`.
nixpkgs-unstable:
final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev) system;
    config.allowUnfree = true;
  };
}
