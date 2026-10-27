# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Phase 3 key setup (one-time, on a nix-capable machine): `nix run nixpkgs#age -- --version`
      → generate the master identity (`age-keygen -o ~/.config/sops/age/keys.txt`), back it up
      **off-repo**, replace the placeholder recipient in `.sops.yaml` with its public key
- [ ] Bootstrap local nix: install the NixOS-WSL distro (PLAN Phase 1.5) — releases ship `.wsl`
      bundles now (checked 2026-10-27: tag 2605.7.2): download `nixos.wsl`, then
      `wsl --install --from-file nixos.wsl` (older tarballs: `wsl --import nixos <dir> <tarball>`)
      — makes this Windows machine nix-capable, unblocking local validation. The `wsl` host is
      already registered (`cfg.nh.flakeDir` points at `~/nixos-new` on the WSL Linux side)
- [ ] After the bootstrap: clone this repo to `~/nixos-new` inside WSL, then `nh os switch --dry`
      → `nh os test` → `nh os switch` on the `wsl` host
- [ ] On a Nix machine (or WSL2 with nix): `nix flake check` + `nix fmt` the scaffold
- [ ] Push, then run the manual CI workflow (Actions tab) — first `nix flake check` / `nix fmt`
      verdict plus per-host toplevel builds; then run the flake-update workflow and merge its PR
      to land the first `flake.lock`
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Confirm the identity values in `hosts/*/default.nix` are what you want: username
      (`polishcat`), locale (`Europe/Warsaw`, `en_US.UTF-8`, `pl` keyboard), git email (the
      legacy-flake identity, set in §2.2)
- [ ] Clone the repo onto the other machines at their real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: set `cfg.user.initialHashedPassword` first (locked account otherwise
      — see PLAN Phase 2), then `nh os switch --dry` → `nh os test` → `nh os switch`

## Legacy-flake ports (PLAN §2.2)

Scoped in [PLAN §2.2](PLAN.md); implement after doc sign-off — small items first, medium after:

- [ ] `nix flake check` + `nix fmt` on a nix machine (WSL once bootstrapped) — every module was
      audited against the pinned branch sources (raw nixpkgs/HM files, mynixos) on 2026-10-27:
      ~65 module files verified, 4 eval-breaking bugs found and fixed (font attrs, flatseal,
      delta rename); what remains is the real eval/format run

## Backlog

- [ ] `hyprland.lua` binds `brave-browser.desktop` (SUPER+W) — install Brave (chromium wrapper,
      like the legacy flake) or edit the bind to Firefox

- [ ] Installer ISO — deferred; expand `image.modules.iso` (see PLAN Phase 6), build with
      `nixos-rebuild build-image --flake .#<host> --image-variant iso`
- [ ] Phase 3 — sops-nix secrets
- [ ] Phase 4 leftovers — Plasma HM config (when a host enables Plasma), OBS (opt-in), Stylix
      (deferred — verdict in PLAN Phase 4)
- [ ] Phase 5 — CI (fmt + flake check + per-host toplevel builds)
