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

    wifi.powersave.enable = lib.mkEnableOption "Wi-Fi power saving (NetworkManager)";

    wifi.macRandomization.enable = lib.mkEnableOption ''
      stable per-network randomized Wi-Fi MAC addresses (scanning is randomized
      by upstream already). A different mode (random/preserve/fixed address)
      can be set directly via networking.networkmanager.wifi.macAddress.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.networking.networkManager.enable {
      networking.networkmanager.enable = true;

      # avoid multi-minute boot stalls waiting for a network that may not be there
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

      users.users.${config.cfg.user.name}.extraGroups = [ "networkmanager" ];

      # wifi.powersave upstream is nullOr bool (null = leave NM's default);
      # macAddress "stable" keeps one random MAC per network, not per connect
      networking.networkmanager.wifi.powersave =
        lib.mkIf config.cfg.networking.wifi.powersave.enable true;
      networking.networkmanager.wifi.macAddress =
        lib.mkIf config.cfg.networking.wifi.macRandomization.enable "stable";
    })

    (lib.mkIf config.cfg.networking.firewall.enable {
      networking.nftables.enable = true;
      networking.firewall = {
        inherit (config.cfg.networking.firewall) allowedTCPPorts allowedUDPPorts;
      };
    })
  ];
}
