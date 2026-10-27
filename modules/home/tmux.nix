{
  lib,
  osConfig,
  ...
}:
{
  # opt-in (default false) — enabled on hosts that serve ssh sessions
  config = lib.mkIf osConfig.cfg.home.tmux.enable {
    programs.tmux.enable = true;
  };
}
