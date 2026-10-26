# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Implement **PLAN.md Phase 1** (scaffold) — full executable spec in PLAN.md §1
- [ ] Bootstrap local nix: import the NixOS-WSL tarball with `wsl --import` (PLAN Phase 1.5) —
      makes this Windows machine nix-capable, unblocking local validation
- [ ] On a Nix machine (or WSL2 with nix): `nix flake check` + `nix fmt` the scaffold
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Set real values: confirm username (`polishcat`), git name/email, timezone (`Europe/Warsaw`
      default), keyboard layout (`pl` default)
- [ ] Clone the repo onto each machine at its real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: `nh os switch --dry` → `nh os test` → `nh os switch`

## Backlog

- [ ] Installer ISO — deferred; expand `image.modules.iso` (see PLAN Phase 6), build with
      `nixos-rebuild build-image --flake .#<host> --image-variant iso`
- [ ] Phase 3 — sops-nix secrets
- [ ] Phase 4 — GNOME / Plasma home-manager configs
- [ ] Phase 5 — CI (fmt + flake check + per-host toplevel builds)
