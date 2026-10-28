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
      verdict plus per-host toplevel builds and the installer-ISO eval step; then run the
      flake-update workflow and merge its PR to land the first `flake.lock` (pinning
      nixos-hardware, disko and lanzaboote too)
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Confirm the identity values in `hosts/*/default.nix` are what you want: username
      (`polishcat`), locale (`Europe/Warsaw`, `en_US.UTF-8`, `pl` keyboard), git email (the
      legacy-flake identity, set in §2.2)
- [ ] Clone the repo onto the other machines at their real path; set `cfg.nh.flakeDir` per host
- [ ] First deploy per host: set `cfg.user.initialHashedPassword` first (locked account otherwise
      — see PLAN Phase 2), then `nh os switch --dry` → `nh os test` → `nh os switch`
- [ ] After the desktop's first deploy: verify the theming flow — login seeds
      `~/.local/state/theming/current` + palette renders (bar/mako/kitty/gtk/rofi/hyprlock
      recolor), waypaper (`SUPER+SHIFT+W`) switches wallpaper + rethemes live, reboot restores
      the last pick

## Legacy-flake ports (PLAN §2.2)

Scoped in [PLAN §2.2](PLAN.md); implement after doc sign-off — small items first, medium after:

- [ ] `nix flake check` + `nix fmt` on a nix machine (WSL once bootstrapped) — every module was
      audited against the pinned branch sources (raw nixpkgs/HM files, mynixos) on 2026-10-27:
      ~65 module files verified, 4 eval-breaking bugs found and fixed (font attrs, flatseal,
      delta rename); what remains is the real eval/format run

## Backlog

- [ ] Installer ISO — implemented (`hosts/installer/default.nix`: GDM-autologin Hyprland
      live env); build it on a Nix machine (`nixos-rebuild build-image --flake .#installer
      --image-variant iso`), boot it once to verify the live session, write the .iso to USB
      and do one real install from it
- [ ] Phase 6 dormant modules — enable per host when relevant: `cfg.updates.auto.*` (manual nh
      vs auto trade-off), `cfg.boot.secureBoot.*` (UEFI hardware + real eval first),
      `cfg.attic.*` (server; waits on the sops key + a secret)
- [ ] Phase 4 leftovers — Plasma/OBS are wired (dormant/opt-in), waiting on a host that uses
      them; runtime-theming follow-up: laptop wallpaper set (rofi.rasi and hyprlock colors
      landed 2026-10-28)
- [ ] Phase 5 leftover — cache strategy (Cachix or GH actions cache) if the CI checks get slow
