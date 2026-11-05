# Curried: flake.nix applies `import ./overlays/unstable.nix nixpkgs-unstable`.
# Gives every module (and home-manager module, via useGlobalPkgs) `pkgs.unstable.<pkg>`.
nixpkgs-unstable: final: prev: {
  unstable = import nixpkgs-unstable {
    # NOT `inherit (prev) system` — that reads pkgs.system, the deprecated
    # alias (eval warning); stdenv.hostPlatform.system is supported.
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
}
