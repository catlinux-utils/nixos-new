---
name: add-nixos-module
description: Create or edit a system-level NixOS feature module in modules/nixos/ of this flake. Use whenever the user asks to add a system feature, service or toggle (bluetooth, tailscale, firmware, printing, power management — PLAN Phase 2.1 items), add a system-side cfg.* option, or says "add a module" / "add a nixos module" without specifying home-manager.
---

# Add a NixOS feature module

System features are drop-in files in `modules/nixos/`, auto-imported by
`lib/importNixFiles.nix` — creating the file activates it; no import list or `default.nix`
edits.

## Steps

1. **Create `modules/nixos/<feature>.nix`.** One feature per file, named after the feature.
   Never name a feature file `default.nix` or `hardware-configuration.nix` — the auto-importer
   skips those names.

2. **Follow the module skeleton:**

   ```nix
   {
     lib,
     config,
     ...
   }:
   {
     options.cfg.<feature>.enable = lib.mkEnableOption "<description>";

     config = lib.mkIf config.cfg.<feature>.enable {
       # ...
     };
   }
   ```

   Sub-options sit under the same path (`cfg.<feature>.port`, `cfg.<feature>.libraries`) via
   `lib.mkOption`. Real examples: `modules/nixos/audio.nix` (minimal), `modules/nixos/ssh.nix`
   (sub-options).

3. **Verify every option name against pinned nixpkgs 26.05** — not against latest docs. Use
   search.nixos.org with the release filter set to 26.05, or grep the pinned nixpkgs sources on
   a Nix machine. 26.05 already moved options silently (`services.journald.storage`,
   `hardware.xpadneo.enable`, no `programs.mangohud` module, no `services.flatpak.remotes`).
   For Lix-specific settings, check docs.lix.systems.

4. **Feature implies another feature?** Set the other switch inside your `mkIf` block —
   directly for hard requirements, `lib.mkDefault` when hosts may still override. Worked
   example: `modules/nixos/desktop/hyprland.nix` sets `cfg.desktop.enable` and mkDefaults
   `cfg.graphics.enable` / `cfg.audio.enable`.

5. **Enable nothing by default.** Hosts flip switches in `hosts/<name>/default.nix` (host
   matrix: PLAN.md §1.7). If a sub-option needs a host-specific value you don't know (ports,
   keys, paths), leave a TODO comment in the host file.

6. **Bleeding-edge packages only via `pkgs.unstable.<pkg>`** — never add extra nixpkgs inputs
   for single packages.

## Doc sync

- Ticked work: tick the item's checkbox in PLAN.md (never delete phases or decisions).
- Options beyond `.enable`: add a row to the option table in docs/ARCHITECTURE.md.
- New immediately-actionable follow-ups: TODO.md.

## Validation

This dev machine has no nix — nothing can be built or evaluated locally. Run the `nix-validate`
self-review pass before claiming anything works; `nix flake check` and `nh os switch --dry`
happen on a Nix machine.
