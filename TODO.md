# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Bootstrap local nix: import the NixOS-WSL tarball with `wsl --import` (PLAN Phase 1.5) —
      makes this Windows machine nix-capable, unblocking local validation
- [ ] On a Nix machine (or WSL2 with nix): `nix flake check` + `nix fmt` the scaffold
- [ ] Finish Hyprland home config (PLAN Phase 4): idle/lock (hypridle + hyprlock — needs
      `security.pam.services.hyprlock` system-side), notifications (mako or swaync), screenshots
      (grim + slurp); pick a `cfg.home.hyprland.wallpaper` per host in `hosts/<name>/default.nix`
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Set real values in `hosts/*/default.nix`: git email (commented TODO), confirm the username
      and locale values are what you want
- [ ] Clone the repo onto each machine at its real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: set `cfg.user.initialHashedPassword` first (locked account otherwise
      — see PLAN Phase 2), then `nh os switch --dry` → `nh os test` → `nh os switch`

## Backlog

- [ ] Installer ISO — deferred; expand `image.modules.iso` (see PLAN Phase 6), build with
      `nixos-rebuild build-image --flake .#<host> --image-variant iso`
- [ ] Phase 3 — sops-nix secrets
- [ ] Phase 4 — GNOME / Plasma home-manager configs
- [ ] Phase 5 — CI (fmt + flake check + per-host toplevel builds)
