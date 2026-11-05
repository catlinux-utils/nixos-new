{
  lib,
  config,
  ...
}:
{
  options.cfg.syncthing.enable = lib.mkEnableOption "syncthing (file sync, Web UI on 127.0.0.1:8384)";

  config = lib.mkIf config.cfg.syncthing.enable {
    services.syncthing = {
      enable = true;
      user = config.cfg.user.name;
      group = "users";
      dataDir = "/home/${config.cfg.user.name}";
      configDir = "/home/${config.cfg.user.name}/.config/syncthing";
      # the Web UI owns devices/folders until they are declared here
      overrideDevices = false;
      overrideFolders = false;
      # open sync/discovery ports in the firewall — without them LAN peers
      # are unreachable and sync silently falls back to relays
      openDefaultPorts = true;
    };
  };
}
