# Curried: flake.nix applies `import ./overlays/unstable.nix nixpkgs-unstable`.
# Gives every module (and home-manager module, via useGlobalPkgs) `pkgs.unstable.<pkg>`.
nixpkgs-unstable: final: prev: {
  unstable = import nixpkgs-unstable {
    # NOT `inherit (prev) system` — that reads pkgs.system, the deprecated
    # alias (nixpkgs warns "'system' has been renamed …" at eval time).
    # stdenv.hostPlatform.system is the supported spelling.
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
}
