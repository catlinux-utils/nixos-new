# secrets

Lands in Phase 3 (sops-nix): encrypted `secrets/*.yaml` gets committed here and
decrypted on the hosts by `modules/nixos/secrets.nix` behind `cfg.secrets.enable`.

Until then: **never commit plaintext secrets.** `.gitignore` guards everything
in this directory except this README.
