{
  lib,
  osConfig,
  ...
}:
{
  # rides the system desktop switch — the headless vscode-server story is
  # nix-ld (modules/nixos/compat.nix), not a local editor install
  config = lib.mkIf osConfig.cfg.desktop.enable {
    # extensions stay mutable (install from the IDE); declarative profiles
    # land here once the extension set is decided
    programs.vscode.enable = true;
  };
}
