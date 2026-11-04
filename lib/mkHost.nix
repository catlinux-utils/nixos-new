# Curried: flake.nix supplies the global args, each host call supplies the
# per-host args. Relative paths resolve from lib/, hence the ../.
{
  lib,
  self,
  home-manager,
  inputs,
  unstable-overlay,
}:
{
  hostname,
  system ? "x86_64-linux",
  extraModules ? [ ],
}:

lib.nixosSystem {
  inherit system;
  # `self` = the flake's own git-cleaned source tree (a store path); the
  # installer ISO uses it to embed the repo in the live environment
  specialArgs = {
    inherit inputs self;
  };

  modules = [
    (
      { config, ... }:
      {
        options.cfg.git.remote = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Origin URL for the flake working copy at cfg.nh.flakeDir.
            scripts/nixos-copy-repo reads it from the host file and
            preconfigures the delivered copy's git (origin + main tracking) —
            so later hardware-configuration changes can be committed (identity:
            cfg.home.git) and pushed from the host itself.
          '';
        };

        config = {
          networking.hostName = hostname;
          # default flake home: derived from the identity option, not a hardcoded
          # username; hosts override it (wsl) and the installer inherits it as-is
          cfg.nh.flakeDir = lib.mkDefault "/home/${config.cfg.user.name}/github/nixos";

          # NOTE: git wiring of the delivered working copy (origin + tracking)
          # lives in scripts/nixos-copy-repo — the only path that puts the repo
          # on a host — not in an activation script; keep it that way unless a
          # second delivery path appears.

        };
      }
    )
    { nixpkgs.overlays = [ unstable-overlay ]; }
    ../modules/nixos
    ../hosts/${hostname}

    home-manager.nixosModules.home-manager
    (
      { config, ... }:
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        # unmanaged files HM takes over get a .backup copy instead of
        # failing activation
        home-manager.backupFileExtension = "backup";
        # user name comes from users.nix's option (lazy evaluation makes
        # this work); username/homeDirectory are pinned to the NixOS user
        # so the HM modules never depend on HM's own defaults
        home-manager.users.${config.cfg.user.name} = {
          imports = [ ../modules/home ];
          home.username = config.cfg.user.name;
          home.homeDirectory = "/home/${config.cfg.user.name}";
        };
        # HM has no home.stateVersion default — set it here, once, per host
        # (first-install marker: do NOT bump it together with the nixpkgs pin)
        home-manager.sharedModules = [ { home.stateVersion = "26.05"; } ];
      }
    )
  ]
  ++ extraModules;
}
