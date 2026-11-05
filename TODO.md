# TODO

Only items actionable right now. Phases and long-term work live in [PLAN.md](PLAN.md).

## Next

- [ ] Phase 3 key setup (one-time, on this nix-capable machine): `nix run nixpkgs#age -- --version`
      → generate the master identity (`age-keygen -o ~/.config/sops/age/keys.txt`), back it up
      **off-repo**, replace the placeholder recipient in `.sops.yaml` with its public key
- [ ] Per host (Phase 2): replace placeholder `hardware-configuration.nix` with real
      `nixos-generate-config` output from that machine
- [ ] Per host (Phase 2): replace nixos-hardware placeholders with real model modules
- [x] Disk preparation scripts: `scripts/nixos-disk` (partition+format), `scripts/nixos-mount`
      (mount / `--umount`), `scripts/nixos-format-part` — documented in README with install examples
- [ ] Confirm the identity values in `hosts/*/default.nix` are what you want: username
      (`cat`), locale (`Europe/Warsaw`, `en_US.UTF-8`, `pl` keyboard), git email (the
      legacy-flake identity, set in §2.2)
- [ ] Clone the repo onto the other machines at `~/github/nixos` (`cfg.nh.flakeDir` now points there)
- [ ] First deploy per host: set `cfg.user.initialPassword` first (locked account otherwise
      — see PLAN Phase 2), then `nh os switch --dry` → `nh os test` → `nh os switch`
- [ ] After the desktop's first deploy: verify the theming flow — login seeds
      `~/.local/state/theming/current` + palette renders (bar/mako/kitty/gtk/rofi/hyprlock
      recolor), waypaper (`SUPER+SHIFT+W`) switches wallpaper + rethemes live, reboot restores
      the last pick

## Legacy-flake ports (PLAN §2.2)

Scoped in [PLAN §2.2](PLAN.md); implement after doc sign-off — small items first, medium after.

## Backlog

- [ ] Installer ISO — built for real (2026-11-03: `nixos-rebuild build-image --flake
      .#installer --image-variant iso` exit 0; 3.9 GB hybrid ISO, BIOS+UEFI bootable,
      autologin resolves to the `hyprland-uwsm` session; boot-tested in a VM through several
      fix rounds — uwsm autodetect session, hyprpaper 0.8 conf, fidelity palette). Remaining:
      write the .iso to USB and do one real install from it
- [ ] Phase 6 dormant modules — enable per host when relevant: `cfg.updates.auto.*` (manual nh
      vs auto trade-off), `cfg.attic.*` (server; waits on the sops key + a secret).
      `cfg.boot.secureBoot.*` is live everywhere but wsl (2026-11-04) — first real boot per host
      still pends: autoKeys generates the sbctl bundle, autoEnrollKeys stages firmware enrollment
- [ ] nixos-hardware — replace placeholder imports in `hosts/laptop` + `hosts/server`
      `default.nix` with real model modules (`desktop`/`desktop-lite` done 2026-11-05:
      common-gpu-amd + common-cpu-amd + gigabyte-b650)
- [ ] Phase 4 leftovers — Plasma/OBS are wired (dormant/opt-in), waiting on a host that uses
      them
- [ ] Phase 5 leftover — cache strategy (Cachix or GH actions cache) if the CI checks get slow
