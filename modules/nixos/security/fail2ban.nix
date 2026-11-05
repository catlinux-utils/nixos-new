# Upstream wires the rest: the sshd jail attaches when services.openssh.enable
# (cfg.ssh.enable), the DEFAULT jail reads the journal, the banaction follows
# networking.nftables.
{
  lib,
  config,
  ...
}:
{
  options.cfg.fail2ban = {
    enable = lib.mkEnableOption "fail2ban (brute-force banning; protects sshd)";

    ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        IPs/CIDRs fail2ban must never ban. Put the admin's own addresses here —
        upstream already whitelists loopback.
      '';
    };
  };

  config = lib.mkIf config.cfg.fail2ban.enable {
    services.fail2ban = {
      enable = true;
      inherit (config.cfg.fail2ban) ignoreIP;
      # repeat offenders get exponentially longer bans (upstream multipliers)
      bantime-increment.enable = true;
    };
  };
}
