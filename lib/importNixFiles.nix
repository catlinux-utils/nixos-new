# Curried: (import ../../lib/importNixFiles.nix) lib ./.   — called from a default.nix
lib: dir:
map (path: import path) (
  lib.filter (
    path:
    lib.hasSuffix ".nix" path
    && baseNameOf path != "default.nix"
    && baseNameOf path != "hardware-configuration.nix"
  ) (lib.filesystem.listFilesRecursive dir)
);
