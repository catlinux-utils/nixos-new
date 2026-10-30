# Monitoring services — flip whichever fits. None of them open the firewall:
# the node exporter (9100) and Netdata (19999) listen on all interfaces but
# stay unreachable until a port is opened per host — scrape over Tailscale or
# add it to cfg.networking.firewall.allowedTCPPorts; Uptime Kuma binds
# 127.0.0.1:3001 and expects a reverse proxy or an SSH tunnel. Dashboards
# don't page anyone — configure a push channel (Uptime Kuma's built-in
# notifiers cover ntfy and healthchecks-style pings).
{
  lib,
  config,
  ...
}:
{
  options.cfg.monitoring = {
    nodeExporter.enable = lib.mkEnableOption "the Prometheus node exporter (metrics on port 9100)";

    netdata.enable = lib.mkEnableOption "the Netdata real-time dashboard (port 19999)";

    uptimeKuma.enable = lib.mkEnableOption "Uptime Kuma (localhost:3001, uptime checks + notifications)";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.monitoring.nodeExporter.enable {
      services.prometheus.exporters.node.enable = true;
    })

    (lib.mkIf config.cfg.monitoring.netdata.enable {
      services.netdata.enable = true;
    })

    (lib.mkIf config.cfg.monitoring.uptimeKuma.enable {
      services.uptime-kuma.enable = true;
    })
  ];
}
