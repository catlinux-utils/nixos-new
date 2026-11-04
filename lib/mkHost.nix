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
      { config, pkgs, ... }:
      {
        options.cfg.git.remote = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Origin URL for the flake working copy at cfg.nh.flakeDir. When set
            and the directory isn't a git repo (e.g. the git-cleaned copy the
            installer flow delivers via scripts/nixos-copy-repo), activation
            inits one with this remote — so later hardware-configuration
            changes can be committed (identity: cfg.home.git) and pushed from
            the host itself.
          '';
        };

        config = {
          networking.hostName = hostname;
          # default flake home: derived from the identity option, not a hardcoded
          # username; hosts override it (wsl) and the installer inherits it as-is
          cfg.nh.flakeDir = lib.mkDefault "/home/${config.cfg.user.name}/github/nixos";

          # host-assembly git wiring: one-shot at activation, only when the
          # flake dir exists and has no .git (a manual clone or a previous run
          # leaves it alone). Runs as root, so the fresh .git is handed to the
          # host's user; identity comes from the HM-side git config at commit
          # time.
          system.activationScripts.repoGit = lib.mkIf (config.cfg.git.remote != null) (
            lib.stringAfter [ "users" "groups" ] ''
              dir="${toString config.cfg.nh.flakeDir}"
              if [ -d "$dir" ] && [ ! -e "$dir/.git" ]; then
                ${pkgs.git}/bin/git -C "$dir" init -b main
                ${pkgs.git}/bin/git -C "$dir" remote add origin ${config.cfg.git.remote}
                chown -R ${config.cfg.user.name}:users "$dir/.git"
              fi
            ''
          );
        };
      }
    )
    { nixpkgs.overlays = [ unstable-overlay ]; }
    # declares the `disko` option that hosts/<name>/disko.nix sets; hosts
    # without a layout (wsl, installer) simply leave it unset
    inputs.disko.nixosModules.default
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
