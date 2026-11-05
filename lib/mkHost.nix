# Curried: flake.nix supplies the global args, each host call the per-host
# args. Relative paths resolve from lib/, hence the ../.
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
  # `self` = the flake's git-cleaned source (store path); the installer
  # ISO embeds it in the live environment
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
          # declared here, not a feature module: per-host knob consumed by
          # scripts/nixos-copy-repo
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
          # derived from the identity option, not hardcoded; wsl overrides,
          # the installer inherits
          cfg.nh.flakeDir = lib.mkDefault "/home/${config.cfg.user.name}/github/nixos";

          # git wiring of the delivered working copy (origin + tracking) lives
          # in scripts/nixos-copy-repo — keep it there unless a second
          # delivery path appears.

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
        # files HM takes over get a .backup copy instead of failing activation
        home-manager.backupFileExtension = "backup";
        # user name from users.nix's option (lazy evaluation makes this work);
        # username/homeDirectory pinned to the NixOS user so HM defaults never win
        home-manager.users.${config.cfg.user.name} = {
          imports = [ ../modules/home ];
          home.username = config.cfg.user.name;
          home.homeDirectory = "/home/${config.cfg.user.name}";
        };
        # no HM home.stateVersion default — set once here (first-install
        # marker: do NOT bump with the nixpkgs pin); hard definition so a
        # duplicate fails eval loudly
        home-manager.sharedModules = [ { home.stateVersion = "26.05"; } ];
      }
    )
  ]
  ++ extraModules;
}
