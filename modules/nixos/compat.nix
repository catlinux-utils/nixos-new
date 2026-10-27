{
  lib,
  config,
  ...
}:
{
  options.cfg.compat = {
    nix-ld.enable = lib.mkEnableOption "nix-ld (run non-Nix prebuilt binaries)";

    nix-ld.libraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Libraries made available to non-Nix binaries via nix-ld.";
    };

    envfs.enable = lib.mkEnableOption "envfs (FUSE /bin and /usr/bin for shebangs)";

    appimage.enable = lib.mkEnableOption "AppImage support (binfmt)";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.compat.nix-ld.enable {
      programs.nix-ld = {
        enable = true;
        libraries = config.cfg.compat.nix-ld.libraries;
      };
    })

    (lib.mkIf config.cfg.compat.envfs.enable {
      services.envfs.enable = true;
    })

    (lib.mkIf config.cfg.compat.appimage.enable {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    })
  ];
}
