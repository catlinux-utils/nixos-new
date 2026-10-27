# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Bootstrap local nix: import the NixOS-WSL tarball with `wsl --import` (PLAN Phase 1.5) —
      makes this Windows machine nix-capable, unblocking local validation. The `wsl` host is
      already registered (`cfg.nh.flakeDir` points at `~/nixos-new` on the WSL Linux side)
- [ ] After the bootstrap: clone this repo to `~/nixos-new` inside WSL, then `nh os switch --dry`
      → `nh os test` → `nh os switch` on the `wsl` host
- [ ] On a Nix machine (or WSL2 with nix): `nix flake check` + `nix fmt` the scaffold
- [ ] Pick a `cfg.home.hyprland.wallpaper` per host in `hosts/<name>/default.nix` (hyprpaper is
      wired; it just needs the image)
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Set real values in `hosts/*/default.nix`: git email (commented TODO), confirm the username
      and locale values are what you want
- [ ] Clone the repo onto the other machines at their real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: set `cfg.user.initialHashedPassword` first (locked account otherwise
      — see PLAN Phase 2), then `nh os switch --dry` → `nh os test` → `nh os switch`

## Backlog

- [ ] Installer ISO — deferred; expand `image.modules.iso` (see PLAN Phase 6), build with
      `nixos-rebuild build-image --flake .#<host> --image-variant iso`
- [ ] Phase 3 — sops-nix secrets
- [ ] Phase 4 — GNOME / Plasma home-manager configs
- [ ] Phase 5 — CI (fmt + flake check + per-host toplevel builds)
