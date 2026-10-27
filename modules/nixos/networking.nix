{
  lib,
  config,
  ...
}:
{
  options.cfg.networking = {
    networkManager.enable = lib.mkEnableOption "NetworkManager (desktop networking)";

    firewall.enable = lib.mkEnableOption "the nftables-backed firewall" // {
      default = true;
    };
    firewall.allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "TCP ports to open in the firewall.";
    };
    firewall.allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "UDP ports to open in the firewall.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.networking.networkManager.enable {
      networking.networkmanager.enable = true;

      # avoid multi-minute boot stalls waiting for a network that may not be there
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

      users.users.${config.cfg.user.name}.extraGroups = [ "networkmanager" ];
    })

    (lib.mkIf config.cfg.networking.firewall.enable {
      networking.nftables.enable = true;
      networking.firewall = {
        inherit (config.cfg.networking.firewall) allowedTCPPorts allowedUDPPorts;
      };
    })
  ];
}
