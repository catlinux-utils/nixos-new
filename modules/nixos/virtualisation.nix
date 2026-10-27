{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.virtualisation = {
    docker.enable = lib.mkEnableOption "Docker with weekly auto-prune";
    podman.enable = lib.mkEnableOption "rootless Podman with a Docker-compatible socket";
    libvirt.enable = lib.mkEnableOption "libvirtd and virt-manager";
  };

  # both container stacks own the docker socket — enabling two is a mistake
  assertions = [
    {
      assertion =
        !(config.cfg.virtualisation.docker.enable && config.cfg.virtualisation.podman.enable);
      message = "cfg.virtualisation: docker and podman are mutually exclusive (shared docker socket).";
    }
  ];

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

    (lib.mkIf config.cfg.virtualisation.podman.enable {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerCompat = true;
          dockerSocket.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        docker-compose
        distrobox
      ];

      environment.sessionVariables.PODMAN_COMPOSE_WARNING_LOGS = "false";

      users.users.${config.cfg.user.name}.extraGroups = [ "podman" ];
    })

    (lib.mkIf config.cfg.virtualisation.libvirt.enable {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;

      users.users.${config.cfg.user.name}.extraGroups = [ "libvirtd" ];
    })
  ];
}
