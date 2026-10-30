# Phase 3 — sops-nix. The import is inert until a host enables
# cfg.secrets.enable and declares sops.secrets entries; consumers reference
# decrypted files via config.sops.secrets.<name>.path, never the value
# (store-leak rule: anything interpolated into Nix lands in the world-
# readable store).
{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.cfg.secrets.enable = lib.mkEnableOption "sops-nix secrets (age key derived from the SSH host key)";

  config = lib.mkIf config.cfg.secrets.enable {
    # decryption derives from each host's ed25519 SSH host key — no separate
    # key enrollment step; a host without that key needs an explicit
    # sops.age.keyFile instead
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # default encrypted file; per-secret `sopsFile` overrides this
    sops.defaultSopsFile = ../../secrets/secrets.yaml;
  };
}
