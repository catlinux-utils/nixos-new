{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.ssh.enable {
    # client-side pair for the keys-only server in modules/nixos/ssh.nix
    programs.ssh = {
      enable = true;
      # the legacy default block is deprecated upstream — we set what we want
      enableDefaultConfig = false;
      # the top-level controlMaster/etc. aliases are deprecated (HM drops
      # their default-generated block) — use settings
      settings."*" = {
        AddKeysToAgent = "yes";
        ControlMaster = "auto";
        ControlPersist = "10m";
      };
    };
  };
}
