{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.ssh.enable {
    # client-side pair for the keys-only server in modules/nixos/ssh.nix;
    # per-host aliases belong in host-specific matchBlocks later
    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      controlMaster = "auto";
      controlPersist = "10m";
    };
  };
}
