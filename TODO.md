# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Implement **PLAN.md Phase 1** (scaffold) — full executable spec in PLAN.md §1
- [ ] On a Nix machine (or WSL2 with nix): `nix flake check` + `nix fmt` the scaffold
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Set real values: confirm username (`polishcat`), git name/email, timezone (`Europe/Warsaw`
      default), keyboard layout (`pl` default)
- [ ] Clone the repo onto each machine at its real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: `nh os switch --dry` → `nh os test` → `nh os switch`

## Backlog

- [ ] Installer ISO (e.g. `image.modules.iso` pattern) — deferred for now
- [ ] Phase 3 — sops-nix secrets
- [ ] Phase 4 — GNOME / Plasma home-manager configs
- [ ] Phase 5 — CI (fmt + flake check)
