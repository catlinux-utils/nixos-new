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
      # the legacy default block is deprecated upstream; we set exactly what we
      # want below
      enableDefaultConfig = false;
      # the top-level controlMaster/controlPersist/addKeysToAgent aliases are
      # deprecated (HM will drop their default-generated block) — use settings
      settings."*" = {
        AddKeysToAgent = "yes";
        ControlMaster = "auto";
        ControlPersist = "10m";
      };
    };
  };
}
