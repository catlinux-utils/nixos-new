# AGENTS.md — operating manual for agent sessions

Guidance for AI agents (and humans) working in this repo. The roadmap lives in
[PLAN.md](PLAN.md); how the config fits together lives in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## What this repo is

A NixOS flake managing multiple machines (`desktop`, `laptop`, `server`) with Home Manager wired in
as a NixOS module. All custom options live under the `cfg.*` namespace. Rebuilds happen
through `nh`.

## Environment constraints (read first)

- The dev machine is Windows **without nix**. You cannot build, evaluate, format, or lock anything
  there.
- Never claim a build/eval/fmt ran unless you actually ran it on a Nix machine (or WSL2 with nix).
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
hosts/<name>/          default.nix (feature switches) + hardware-configuration.nix
modules/nixos/         system feature modules (auto-imported, cfg.* options)
modules/home/          home-manager feature modules (auto-imported)
docs/                  ARCHITECTURE.md
PLAN.md TODO.md        what to do / what to do next
```

## Markdown maintenance rules

- **PLAN.md** — source of truth for what to do. Tick checkboxes as work completes; never delete
  phases or decisions.
- **TODO.md** — only currently actionable items. When done: tick in PLAN.md, drop from here.
- **docs/ARCHITECTURE.md** — update whenever the folder scheme, option tree, or data flow changes.
- **README.md** — keep the host table and usage commands accurate.
- Keep every md file self-contained enough that a fresh session can orient without conversation
  history.

## Nix style

- Format with `nix fmt` (RFC 101 style via `nixfmt-rfc-style`): 2-space indent, arguments stay on
  one line when they fit, final newline. Don't hand-format against nixfmt's choices.
- Prefer `lib.mkEnableOption` / `lib.mkIf` / `lib.mkOption` over raw attrsets.
- One feature per file; the file is named after the feature (`ssh.nix`, `gaming.nix`).

## Feature-module pattern (checklist)

1. File goes in `modules/nixos/` (system) or `modules/home/` (user) — **auto-imported**, no import
   list edits, no default.nix changes.
2. Declare `options.cfg.<feature>.enable = lib.mkEnableOption "<description>";`
3. Wrap all config in `config = lib.mkIf config.cfg.<feature>.enable { ... };`
4. Home-side modules that must follow a system switch read it via `osConfig.cfg.*`.
5. Enable nothing by default — hosts flip the switches in `hosts/<name>/default.nix`.
6. A feature that implies another uses `mkDefault`/direct set of the other's switch (see
   `desktop/hyprland.nix` setting `cfg.desktop.enable` in PLAN.md §1.5).

## Recipes

### Add a host

1. Create `hosts/<name>/default.nix` — flip feature switches, set `cfg.user.name`,
   `cfg.locale.*`, `cfg.nh.flakeDir` as needed.
2. Create `hosts/<name>/hardware-configuration.nix` — real one from `nixos-generate-config` on the
   machine (never hand-write disk config).
3. Register in `flake.nix`: `nixosConfigurations.<name> = mkHost { hostname = "<name>"; };`
4. Update README host table, PLAN.md status, ARCHITECTURE.md if the scheme changed.

### Add a NixOS module

1. Create `modules/nixos/<feature>.nix` following the pattern checklist (auto-imported).
2. Enable it in the relevant `hosts/*/default.nix`.
3. If it exposes sub-options beyond `.enable`, document them in ARCHITECTURE.md's option table.

### Add a home module

1. Create `modules/home/<feature>.nix` following the pattern checklist (auto-imported).
2. Use `osConfig.cfg.*` when user config must follow a system switch.

### Wire a secret

Only after Phase 3 (sops-nix) is implemented — see PLAN.md. Never commit plaintext secrets;
`.gitignore` guards `secrets/` until sops lands.

## Commit hygiene

- Small, focused commits; imperative subject ("add nh module", not "added nh module").
- Resolve `flake.lock` conflicts by regenerating on a Nix machine (`nix flake update` for full
  refresh, `nix flake lock --update-input <input>` for one), never by hand-editing.
