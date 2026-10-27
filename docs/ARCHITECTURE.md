# Architecture

How this flake is wired together. For the work queue see [../PLAN.md](../PLAN.md); for conventions
and recipes see [../AGENTS.md](../AGENTS.md).

> Status: Phase 1 (scaffold) implemented — this document describes the implemented design, pending
> first machine validation (`nix flake check`, `nix fmt` on a Nix machine; see TODO.md).

## Data flow

```
flake.nix
  ├─ inputs: nixpkgs (26.05) ◄── home-manager (release-26.05, follows nixpkgs)
  │          nixpkgs-unstable
  │          nixos-wsl (follows nixpkgs) — imported by the wsl host only
  │          sops-nix (follows nixpkgs) — secrets module (cfg.secrets.enable)
  │          plasma-manager (follows nixpkgs + home-manager) — HM module for the
  │            dormant plasma home config (no host enables cfg.desktop.plasma.enable yet)
  │
  ├─ overlays/unstable.nix ──────► pkgs.unstable.<pkg> available in every module
  │
  └─ lib/mkHost.nix ──► nixosConfigurations.<host>
        ├─ modules/nixos/          system feature modules (cfg.* options)
        ├─ hosts/<host>/           hardware-configuration.nix + per-host switches
        └─ home-manager.nixosModules.home-manager
              └─ modules/home/     user feature modules
                    └─ read system switches via osConfig.cfg.*

nh (configured in modules/nixos/nh.nix, flake path = cfg.nh.flakeDir):
  nh os switch    builds & activates nixosConfigurations.<hostname>  (OS + Home Manager)
  nh home switch  user environment only
  nh clean        daily garbage collection (--keep 5 --keep-since 3d); nix.gc.automatic stays off
```

## Folder scheme (annotated)

See PLAN.md §1.2 for the full tree. The load-bearing parts:

- **`lib/mkHost.nix`** — the only place host assembly happens. One host = one directory under
  `hosts/` + one line in `flake.nix`. It sets `networking.hostName`, applies the unstable overlay,
  imports `modules/nixos/` and `hosts/<name>/`, and wires `home-manager.nixosModules.home-manager`
  to the user named by `config.cfg.user.name` (with `home.username`/`home.homeDirectory` pinned to
  that user). Unmanaged files that HM takes over are backed up
  (`home-manager.backupFileExtension = "backup"`) instead of failing activation.
- **`lib/importNixFiles.nix`** — recursive importer used by both `default.nix` importers. It skips
  `default.nix` (would recurse) and `hardware-configuration.nix`. Consequence: **drop-in modules**
  — creating `modules/nixos/foo.nix` makes it active with zero import edits.
- **`hosts/<name>/default.nix`** — the self-contained host entry: one `cfg = { ... }` tree,
  sectioned identity (`user`), locale, `nh.flakeDir`, git identity (`home.git`), then feature
  switches; plus the per-host nixos-hardware import (Phase 2). No implementation logic. The
  `wsl` host is the platform exception: it imports `nixosModules.wsl` via `specialArgs.inputs`
  and has no `hardware-configuration.nix` — NixOS-WSL owns boot and the filesystem.
- **`modules/nixos/desktop/base.nix`** — shared desktop plumbing (fonts, portals, xdg). DE modules
  enable it themselves, so a host sets exactly one switch to get a working session; an `assertions`
  guard makes enabling two DEs fail evaluation.
- **Hyprland session flow** — the system side launches the session through uwsm
  (`programs.hyprland.withUWSM`), which activates `graphical-session.target`. User units (the
  quickshell bar, hypridle, mako, hyprpaper, the polkit agent) bind to it from the home side
  (`modules/home/hyprland/`), so nothing is autostarted via `exec-once`. The session config
  itself is a plain vendored file (`modules/home/hyprland/hyprland.lua`, Hyprland's Lua config
  format) copied verbatim to `~/.config/hypr/` — kept interpolation-free so it doubles as a
  portable config for non-NixOS machines; the rofi launcher and its rasi follow the same pattern.
  Hyprlock (spawned by
  hypridle's `lock_cmd`) authenticates through the `security.pam.services.hyprlock` service the
  system side creates. Hyprland's own HM systemd integration is disabled
  (`wayland.windowManager.hyprland.systemd.enable = false`) — uwsm owns target activation.

## The option tree

All switches live under the flat `cfg.*` namespace. The complete reference — every option with
type, default, effect and which hosts set it — lives in [OPTIONS.md](OPTIONS.md); when an option
is added, changed or a host wiring flips, update that file in the same change (the sync-docs
skill covers it).

## The `osConfig` bridge

Because Home Manager is integrated as a NixOS module, home modules evaluate in the same module
system as the host and receive `osConfig` (the host's final config). Home modules are
**option-less** — every knob they gate on lives in the host's `cfg.*` tree (home-feature options
are declared in `modules/nixos/home-options.nix`), read via `osConfig`:

```nix
# modules/home/hyprland/session.nix
config = lib.mkIf osConfig.cfg.desktop.hyprland.enable { ... };
```

Rule of thumb: the *system* decides whether a feature exists and what its options are; the *home*
layer adds user-facing configuration for it. Hosts set both sides through the same flat `cfg.*`
namespace. Some home modules ride a system switch with no option of their own — e.g.
`browser.nix`, `theming.nix`, `vscode.nix` and `mpv.nix` gate on `cfg.desktop.enable`,
`gnome.nix` on `cfg.desktop.gnome.enable` (like the `hyprland/` folder), so headless hosts don't
carry GUI software.

## Unstable overlay

`overlays/unstable.nix` (applied by `mkHost`) exposes a second package set as `pkgs.unstable`.
Any module — system or home (via `useGlobalPkgs = true`) — can pin a bleeding-edge package with
`pkgs.unstable.<name>` while everything else stays on stable 26.05. This is the only unstable
mechanism; don't add alternate import paths.

## Host assembly walkthrough (what `nh os switch` evaluates)

1. `flake.nix` output `nixosConfigurations.<hostname>` ← `mkHost { hostname = "<hostname>"; }`
2. `mkHost` builds `lib.nixosSystem` with: hostname, unstable overlay, `modules/nixos/` (all
   feature modules, inert until switched on), `hosts/<hostname>/` (hardware + switches), and the
   Home Manager module whose `users.<name>` imports `modules/home/`.
3. Host switches (e.g. `desktop`: Hyprland) cascade — DE module pulls in `desktop/base.nix`,
   `mkDefault`s graphics/audio on.
4. nh finds the flake via `programs.nh.flake` (`cfg.nh.flakeDir`, which sets `NH_FLAKE`)
   and applies the config for the current hostname.
