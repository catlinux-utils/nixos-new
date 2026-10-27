# AGENTS.md — operating manual for agent sessions

Guidance for AI agents (and humans) working in this repo. The roadmap lives in
[PLAN.md](PLAN.md); how the config fits together lives in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## What this repo is

A NixOS flake managing multiple machines (`desktop`, `laptop`, `server`, plus `wsl` — a
NixOS-WSL dev host, Phase 1.5) with Home Manager wired in as a NixOS module. All custom options
live under the `cfg.*` namespace. Rebuilds happen through `nh`. Hosts run Lix, pinned to
nixpkgs **26.05** + Home Manager **release-26.05**.

## Environment constraints (read first)

- The dev machine is Windows **without nix**. You cannot build, evaluate, format, or lock anything
  there.
- Never claim a build/eval/fmt ran unless you actually ran it on a Nix machine (or WSL2 with nix).
- The `wsl` host (PLAN Phase 1.5) exists to dissolve this constraint — once its distro is
  bootstrapped (`wsl --import`, pending), validation runs locally via `wsl.exe`.
- All validation happens on a nix-capable environment:
  - `nix flake check`
  - `nix fmt` (formatter output exists once Phase 1 lands)
  - `nh os switch --dry` / `nh os test` on a target host
- Because local proof is impossible, be extra careful with option names and import paths. Verify
  option names against the **pinned** nixpkgs (grep the flake's nixpkgs store path on a Nix
  machine, or search.nixos.org filtered to the pinned release) — not against latest docs.
- Hosts run **Lix** (`nix.package = pkgs.lixPackageSets.latest.lix`, set in
  `modules/nixos/nix.nix`) — CLI-compatible with `nix`, so the commands above work unchanged;
  check Lix-specific settings against docs.lix.systems.

## Repo map

```
flake.nix              inputs + outputs; declares the hosts via mkHost
lib/                   mkHost.nix (host assembler), importNixFiles.nix (auto-importer)
overlays/unstable.nix  pkgs.unstable.<pkg> for everything
.github/workflows/     manual CI (fmt + flake check + per-host toplevel builds), flake-update PR
hosts/<name>/          default.nix (feature switches) + hardware-configuration.nix;
                       wsl has none (NixOS-WSL owns boot/disks)
hosts/installer/       ISO media module — image, not a host (deferred, PLAN Phase 6)
modules/nixos/         system feature modules (auto-imported, cfg.* options);
                       includes desktop/{base,gnome,hyprland,plasma}.nix, compat.nix,
                       sandbox.nix
modules/home/          home-manager feature modules (auto-imported); includes
                       xdg.nix, home-tools.nix, hyprland/ (session config)
docs/ARCHITECTURE.md   how it all fits together
docs/OPTIONS.md        every cfg.* option: type, default, effect, per-host matrix
PLAN.md TODO.md        roadmap / actionable next steps
AGENTS.md README.md    this file / project overview
```

## Markdown maintenance rules

- **PLAN.md** — source of truth for what to do. Tick checkboxes as work completes; never delete
  phases or decisions.
- **TODO.md** — only currently actionable items. When done: tick in PLAN.md, drop from here.
- **docs/ARCHITECTURE.md** — update whenever the folder scheme, option tree, or data flow changes.
- **docs/OPTIONS.md** — the complete `cfg.*` reference (types, defaults, per-host matrix); update
  in the same change whenever an option is added, renamed, or a host wiring flips.
- **AGENTS.md** — update in the same change whenever a convention itself changes (namespace, pin
  bumps, new patterns); this is the first file a fresh agent reads.
- **README.md** — keep the host table and usage commands accurate.
- Keep every md file self-contained enough that a fresh session can orient without conversation
  history.

## Nix style

- Format with `nix fmt` (RFC 101 style via `nixfmt-rfc-style`): 2-space indent, arguments stay on
  one line when they fit, final newline. Don't hand-format against nixfmt's choices.
- Prefer `lib.mkEnableOption` / `lib.mkIf` / `lib.mkOption` over raw attrsets.
- One feature per file; the file is named after the feature (`ssh.nix`, `gaming.nix`). A feature
  that outgrows one file becomes a folder of sibling `.nix` files (`modules/home/hyprland/`).
- Bleeding-edge packages come only via `pkgs.unstable.<pkg>` (the one overlay) — never add extra
  nixpkgs inputs for single packages.

## Feature-module pattern (checklist)

1. File goes in `modules/nixos/` (system) or `modules/home/` (user) — **auto-imported**, no import
   list edits, no default.nix changes.
2. Declare `options.cfg.<feature>.enable = lib.mkEnableOption "<description>";`
3. Wrap all config in `config = lib.mkIf config.cfg.<feature>.enable { ... };`
4. Home-side modules are option-less: they gate on `osConfig.cfg.*` (including
   `osConfig.cfg.home.*`), whose options are declared in the NixOS tree —
   `modules/nixos/home-options.nix` for home features — so hosts set them under the same
   `cfg.*` namespace.
5. Enable nothing by default — hosts flip the switches in `hosts/<name>/default.nix`.
6. A feature that implies another uses `mkDefault`/direct set of the other's switch (see
   `desktop/hyprland.nix` setting `cfg.desktop.enable` in PLAN.md §1.5).
7. The auto-importer skips files named `default.nix` and `hardware-configuration.nix` — never
   give a feature module either name.
8. A feature folder (`modules/home/hyprland/`) works the same as a single file: every `.nix` in it
   is auto-imported, so the folder must not contain a `default.nix`. Keep one writer per shared
   settings key across the folder's files (no double-owned config).

## Repo helper skills

Project skills live in `.agents/skills/<name>/SKILL.md` and are auto-discovered by ZCode
sessions in this repo. They encode the recipes below as step-by-step procedures — prefer
invoking the matching skill over improvising:

- `add-nixos-module` — new system feature module in `modules/nixos/`
- `add-home-module` — new Home Manager module in `modules/home/` (+ options in
  `home-options.nix`)
- `add-host` — register a machine (`hosts/<name>/` + `flake.nix` entry)
- `nix-validate` — verification protocol for the no-nix-on-Windows constraint (self-review
  pass + what must run on a Nix machine)
- `sync-docs` — bring PLAN/TODO/ARCHITECTURE/AGENTS/README back in sync after a change

Keep a skill and the matching recipe here consistent — when a recipe changes, update the skill
in the same commit.

## Recipes

### Add a host

1. Create `hosts/<name>/default.nix` — the self-contained host entry: one `cfg = { ... }` tree,
   sectioned identity (`user`), locale, `nh.flakeDir`, git identity (`home.git`), then feature
   switches.
2. Create `hosts/<name>/hardware-configuration.nix` — real one from `nixos-generate-config` on the
   machine (never hand-write disk config).
3. Register in `flake.nix`: `nixosConfigurations.<name> = mkHost { hostname = "<name>"; };`
4. Foreign-arch binaries: set `boot.binfmt.emulatedSystems` directly in the host file — per-host
   decision, no toggle.
5. Update README host table, PLAN.md status, ARCHITECTURE.md if the scheme changed.

### Add a NixOS module

1. Create `modules/nixos/<feature>.nix` following the pattern checklist (auto-imported).
2. Enable it in the relevant `hosts/*/default.nix`.
3. If it exposes sub-options beyond `.enable`, document them in ARCHITECTURE.md's option table.

### Add a home module

1. Create `modules/home/<feature>.nix` following the pattern checklist (auto-imported); gate it on
   `osConfig.cfg.home.<feature>.*`.
2. Declare the feature's options in `modules/nixos/home-options.nix` (not in the module) — hosts
   set them under the same flat `cfg.*` tree.
3. Never force-overwrite existing user files — `mkHost` sets
   `home-manager.backupFileExtension = "backup"` as the safety net.

### Wire a secret

Only after Phase 3 (sops-nix) is implemented — see PLAN.md. Never commit plaintext secrets;
`.gitignore` guards `secrets/` until sops lands.

## Commit hygiene

- Terse conventional commits, subject-only: `<type>(<scope>): <imperative summary>`, ≤50 chars,
  no trailing period (e.g. `docs: add compat module (nix-ld, envfs, appimage)`). Body only when
  the why isn't obvious from the diff.
- Resolve `flake.lock` conflicts by regenerating on a Nix machine (`nix flake update` for full
  refresh, `nix flake lock --update-input <input>` for one), never by hand-editing.
