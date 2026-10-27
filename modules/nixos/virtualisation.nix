{
  lib,
  config,
  ...
}:
{
  options.cfg.virtualisation = {
    docker.enable = lib.mkEnableOption "Docker with weekly auto-prune";
    libvirt.enable = lib.mkEnableOption "libvirtd and virt-manager";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.virtualisation.docker.enable {
      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      users.users.${config.cfg.user.name}.extraGroups = [ "docker" ];
    })

    (lib.mkIf config.cfg.virtualisation.libvirt.enable {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;

      users.users.${config.cfg.user.name}.extraGroups = [ "libvirtd" ];
    })
  ];
}
