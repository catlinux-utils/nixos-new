# Phase 3 — sops-nix. Inert until a host enables cfg.secrets.enable; consumers
# reference decrypted files via config.sops.secrets.<name>.path, never the value
# (store-leak rule: interpolated Nix lands in the world-readable store).
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
    # decryption derives from each host's ed25519 SSH host key — no key
    # enrollment step; a host without it needs an explicit sops.age.keyFile
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # default encrypted file; per-secret `sopsFile` overrides this
    sops.defaultSopsFile = ../../secrets/secrets.yaml;
  };
}
