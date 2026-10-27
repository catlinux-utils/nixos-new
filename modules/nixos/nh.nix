{
  lib,
  config,
  ...
}:
{
  options.cfg.nh.flakeDir = lib.mkOption {
    type = lib.types.path;
    default = /etc/nixos;
    description = ''
      Where this flake lives on the machine; used by nh via NH_FLAKE.
    '';
  };

  config = {
    programs.nh = {
      enable = true;
      # sets NH_FLAKE (the bare FLAKE variable is deprecated by nh)
      flake = toString config.cfg.nh.flakeDir;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5";
      };
    };

    # nix.gc.automatic stays off — nh.clean owns garbage collection.
  };
}
