---
name: add-home-module
description: Create or edit a Home Manager feature module in modules/home/ of this flake. Use whenever the user asks for user-level configuration (shell tools, git, browser, editor, direnv, vscode, gpg, theming — PLAN Phase 4 items), or says "add a home module" / "add HM config" / "configure <tool> for my user". Also covers declaring the module's options in modules/nixos/home-options.nix.
---

# Add a Home Manager feature module

User features are drop-in files in `modules/home/`, auto-imported. They are **option-less**:
Home Manager runs as a NixOS module here, so home modules read the host's switches via
`osConfig` instead of declaring their own options.

## Steps

1. **Declare options first — in `modules/nixos/home-options.nix`, never in the module.**
   Home-feature options live under `cfg.home.<feature>.*` so hosts set every knob in one flat
   `cfg.*` tree. Default `enable = true` for anything that belongs in a sane user environment
   (the repo convention); `default = false` only for genuinely opt-in features.

   ```nix
   <feature>.enable = lib.mkOption {
     type = lib.types.bool;
     default = true;
     description = "...";
   };
   ```

2. **Create `modules/home/<feature>.nix`** — a `config` block gated on `osConfig`, no
   `options` block:

   ```nix
   {
     lib,
     osConfig,
     ...
   }:
   {
     config = lib.mkIf osConfig.cfg.home.<feature>.enable {
       # ...
     };
   }
   ```

   If the feature rides an existing *system* feature instead of owning a switch (like the
   Hyprland session config), gate on that system option — e.g.
   `osConfig.cfg.desktop.gnome.enable`, as `modules/home/hyprland/` does for Hyprland.

3. **Real examples:** `modules/home/git.nix` (identity via `cfg.home.git.*`),
   `modules/home/shell.nix` (plain enable), `modules/home/hyprland/` (system-gated feature
   folder — no `default.nix` inside, one writer per settings key across its files).

4. **Verify option names against the pins**: home-manager options against **release-26.05**
   (search.nixos.org has an HM options tab; the pin follows nixpkgs 26.05), NixOS options
   against 26.05. Latest-docs memory is not evidence.

5. **Never force-overwrite existing user files.** `lib/mkHost.nix` sets
   `home-manager.backupFileExtension = "backup"` as the safety net; prefer HM `programs.*`
   options over raw file takeovers.

6. **Bleeding-edge packages only via `pkgs.unstable.<pkg>`** — works in home modules because
   `home-manager.useGlobalPkgs = true`.

7. **Host wiring:** default-true features need nothing in the host files; opt-in features
   (`default = false`) get their switch flipped in `hosts/<name>/default.nix`.

## Doc sync

- Ticked work: tick the PLAN.md checkbox (Phase 4 items mostly).
- New `cfg.home.*` options: extend the `cfg.home.*` row in docs/ARCHITECTURE.md's option table.
- Follow-ups (validation, host switches): TODO.md.

## Validation

No nix on this machine — run the `nix-validate` self-review pass; `nix flake check` happens on
a Nix machine.
