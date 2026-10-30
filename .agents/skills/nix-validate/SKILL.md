---
name: nix-validate
description: Verification protocol for this NixOS flake on a Windows dev machine with no nix. Use after writing or editing any .nix file, before claiming that anything builds/evaluates/works, and when the user asks to "validate", "check", "verify" or "test" the flake or config. Prevents false build claims and pins option names to nixpkgs 26.05.
---

# Validate Nix config (no local nix)

This dev machine is Windows **without nix**. Nothing can be built, evaluated, formatted or
locked here. Every claim of "it builds / evaluates / passes" must trace to an actual run on a
Nix machine (or WSL2 with nix once Phase 1.5 lands — then via `wsl.exe`). Never claim a build
or eval ran unless it actually did.

## What you CAN do locally — the self-review pass

Run this after writing or editing any `.nix` file, before handing off:

1. **Import paths** resolve from each file's own directory. The known cross-tree imports:
   `modules/nixos/default.nix` and `modules/home/default.nix` reach
   `../../lib/importNixFiles.nix`; `lib/mkHost.nix` reaches `../modules/nixos` and
   `../hosts/<hostname>`.
2. **Option names vs pinned 26.05**: verify each nontrivial option against the pinned release.
   Strongest evidence first:
   - raw pinned-branch sources — `raw.githubusercontent.com` for `NixOS/nixpkgs` at
     `nixos-26.05` and `nix-community/home-manager` at `release-26.05`;
     `nixos/modules/module-list.nix` locates a module whose path moved; large files truncate in
     fetch tools, so target small single files
   - [mynixos.com](https://mynixos.com) — rendered package/option pages, e.g.
     `mynixos.com/nixpkgs/package/<attr>`; tracks *current* nixpkgs, so good for "does this
     package attr exist", not for branch-specific option shapes
   - [search.nixos.org](https://search.nixos.org) — NixOS + home-manager option tabs, release
     filter 26.05
   - grep the pinned nixpkgs/home-manager sources on a Nix machine

   Latest-docs memory lies; 26.05 already renamed things (`services.journald.storage`,
   `hardware.xpadneo.enable`, no `programs.mangohud` module, no `services.flatpak.remotes`).
   Lix-specific settings: docs.lix.systems.
3. **Namespace consistency**: all custom options under `cfg.*`; home modules are option-less
   and gate on `osConfig.cfg.*`; home-feature options are declared in
   `modules/nixos/home-options.nix`.
4. **Single-writer check**: grep the settings attrpath across modules. The auto-importer
   activates every file, so an unnoticed second writer of the same key is an eval conflict or a
   silent override — especially inside feature folders like `modules/home/desktop/hyprland/`.
5. **Auto-importer hazards**: no feature file named `default.nix` or
   `hardware-configuration.nix`; no `default.nix` inside feature folders.
6. **Style**: 2-space indent, function arguments on one line when they fit, final newline
   (RFC 101 / nixfmt). Don't hand-chase nixfmt's exact choices — `nix fmt` on a Nix machine is
   the authority.

## What must run on a Nix machine — say so, don't pretend

| Purpose | Command |
|---|---|
| evaluate everything | `nix flake check` |
| formatting | `nix fmt` |
| smoke-test the full stack in QEMU | `nixos-rebuild build-vm --flake .#desktop` |
| per-host rollout | `nh os switch --dry` → `nh os test` → `nh os switch` |

Hosts run **Lix** (`nix.package = pkgs.lixPackageSets.latest.lix` in
`modules/nixos/core/nix.nix`)
— CLI-compatible with `nix`, so the commands above work unchanged.

## Reporting

State exactly which commands ran, where, and what they printed. Anything that didn't run stays
unticked in PLAN.md / listed in TODO.md. `flake.lock` conflicts are also resolved on a Nix
machine (`nix flake update`, or `nix flake lock --update-input <input>` for one input) — never
by hand-editing.
