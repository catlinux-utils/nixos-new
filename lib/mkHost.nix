# Curried: flake.nix supplies the global args, each host call supplies the
# per-host args. Relative paths resolve from lib/, hence the ../.
{
  lib,
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
  specialArgs = { inherit inputs; };

  modules =
    [
      { networking.hostName = hostname; }
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
