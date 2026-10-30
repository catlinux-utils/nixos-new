# Server-oriented kernel/sysctl hardening baseline. Not for desktop hosts —
# the ptrace/perf values get in the way of debugging and profiling tools.
{
  lib,
  config,
  ...
}:
{
  options.cfg.hardening.enable = lib.mkEnableOption "the kernel/sysctl hardening baseline (server-oriented)";

  config = lib.mkIf config.cfg.hardening.enable {
    boot.kernel.sysctl = {
      # info leaks — kptr_restrict 2 goes beyond the NixOS default of 1
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.perf_event_paranoid" = 3;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.sysrq" = 0;

      # BPF — no unprivileged bpf(), JIT spraying hardened for all users
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;

      # network — refuse ICMP redirects and source-routed packets; strict
      # reverse-path filtering (drop packets whose source is unroutable)
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

      # fs.protected_fifos/regular stay off the desktop hosts — they can break
      # multi-user /tmp patterns (why NixOS itself doesn't set them)
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
    };

    # sudo execs only when the invoking user is actually in wheel
    security.sudo.execWheelOnly = true;
  };
}
