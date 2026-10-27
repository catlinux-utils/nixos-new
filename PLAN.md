# PLAN — nixos-new

> **Status:** Phase 1 (scaffold) is implemented but **not yet machine-validated** — `nix flake
> check`, `nix fmt` and `build-vm` still need a Nix machine (Phase 1.5 makes that local). Every
> phase below is written so an agent or human can execute it without further context. Agents: also
> read [AGENTS.md](AGENTS.md) for conventions and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for
> how the pieces fit together. Immediate tasks live in [TODO.md](TODO.md).

## Goal

A single NixOS flake managing every machine from one repo:

- **Multiple hosts** — `desktop`, `laptop`, `server` — assembled by one `mkHost` helper; adding a
  host is one directory + one flake entry.
- **Home Manager** integrated as a NixOS module per host, so a single `nh os switch` applies OS and
  user configuration together.
- **Toggleable feature modules** — every feature (desktop environments, audio, gaming, docker, ssh,
  …) sits behind a `cfg.*.enable` option; hosts flip switches, modules stay machine-agnostic.
- **Stable base + unstable on tap** — `nixpkgs` 26.05 is primary; unstable reachable everywhere as
  `pkgs.unstable.<pkg>` via one overlay.
- **nh** for all rebuild and cleanup operations.

## Ground truth & constraints

- Development happens on a Windows machine **without nix**. Nothing can be built, evaluated,
  formatted, or locked there. Never claim a build ran unless it actually ran on a Nix machine.
- Validation happens on target hosts or any nix-capable environment — see
  [Verification strategy](#111-verification-strategy).
- `flake.lock` is born on the first real `nix flake update` / build; it cannot be generated on the
  dev machine.

## Namespace

All custom options live under one unified `cfg.*` namespace — neutral, greppable, and
collision-free with upstream options (renaming it is one grep-replace). Examples:
`cfg.user.name`, `cfg.nh.flakeDir`, `cfg.desktop.hyprland.enable`, `cfg.audio.enable`.

---

## Phase 1 — Scaffold `[ ]`

Complete spec — implement top to bottom.

### 1.1 `flake.nix`

Inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Outputs (sketch):

```nix
outputs =
  # inputs@ binds the whole attrset — modules reach later-added inputs
  # (nixos-wsl, nixos-hardware, sops-nix) through specialArgs.inputs
  inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    unstable-overlay = import ./overlays/unstable.nix nixpkgs-unstable;
    mkHost = import ./lib/mkHost.nix {
      inherit lib home-manager inputs unstable-overlay;
    };
  in
  {
    nixosConfigurations = {
      desktop = mkHost { hostname = "desktop"; };
      laptop = mkHost { hostname = "laptop"; };
      server = mkHost { hostname = "server"; };
    };

    overlays.default = unstable-overlay;

    formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style; # makes `nix fmt` work

    devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
      packages = with nixpkgs.legacyPackages.${system}; [
        nixfmt-rfc-style
        nil
      ];
    };
  };
```

### 1.2 Folder scheme (target tree)

```
.
├── flake.nix
├── flake.lock                      # born on first build (Nix machine)
├── .gitignore                      # result*, .direnv/, secrets/* (except README, until Phase 3)
├── .editorconfig                   # nix: 2-space, utf-8, lf
├── README.md
├── PLAN.md  TODO.md  AGENTS.md
├── docs/
│   └── ARCHITECTURE.md
├── lib/
│   ├── mkHost.nix                  # curried host assembler (1.3)
│   └── importNixFiles.nix          # recursive auto-importer (1.3)
├── overlays/
│   └── unstable.nix                # exposes pkgs.unstable.<pkg> (1.4)
├── hosts/
│   ├── desktop/{default.nix, hardware-configuration.nix}
│   ├── laptop/{default.nix, hardware-configuration.nix}
│   ├── server/{default.nix, hardware-configuration.nix}
│   └── installer/default.nix        # live-ISO config, not a deployable host (Phase 6)
├── modules/
│   ├── nixos/
│   │   ├── default.nix             # auto-imports every sibling .nix
│   │   ├── boot.nix                # systemd-boot, EFI vars, silent boot, zram
│   │   ├── logging.nix             # journald: persistent storage + size cap
│   │   ├── nix.nix                 # experimental-features, allowUnfree, registry pin
│   │   ├── nh.nix                  # see 1.8
│   │   ├── locale.nix              # timezone/locale/keyboard options
│   │   ├── users.nix               # main user from cfg.user.*
│   │   ├── networking.nix          # NetworkManager behind enable
│   │   ├── audio.nix               # PipeWire + rtkit behind enable
│   │   ├── graphics.nix            # OpenGL/VA-API base GPU stack behind enable
│   │   ├── ssh.nix                 # OpenSSH, keys only, behind enable
│   │   ├── virtualisation.nix      # docker + libvirtd behind enables
│   │   ├── gaming.nix              # Steam + gamescope/gamemode/MangoHud behind enable
│   │   ├── sandbox.nix             # Flatpak (+Flathub, Flatseal) / firejail behind enables
│   │   ├── compat.nix              # nix-ld + envfs + appimage (run non-Nix binaries)
│   │   └── desktop/
│   │       ├── base.nix            # cfg.desktop.enable: fonts, portals, xdg
│   │       ├── gnome.nix
│   │       ├── hyprland.nix
│   │       └── plasma.nix
│   └── home/
│       ├── default.nix             # auto-imports every sibling .nix
│       ├── shell.nix               # zsh + starship + modern CLI tools + aliases
│       ├── git.nix                 # git + delta/lfs; email via option
│       ├── terminal.nix            # kitty
│       ├── neovim.nix              # defaultEditor, aliases
│       ├── xdg.nix                 # xdg.enable, user dirs, mime defaults
│       ├── direnv.nix              # direnv + nix-direnv (Phase 4)
│       ├── nix-index.nix           # nix-index + comma (Phase 4)
│       ├── gpg.nix                 # gpg + gpg-agent w/ ssh-agent (Phase 4)
│       ├── ssh.nix                 # ssh client defaults (Phase 4)
│       ├── browser.nix             # firefox (rides cfg.desktop.enable)
│       ├── vscode.nix              # editor (rides cfg.desktop.enable)
│       ├── mpv.nix                 # video player (rides cfg.desktop.enable)
│       ├── easyeffects.nix         # PipeWire EQ (audio + desktop)
│       ├── password-store.nix      # pass (pairs with gpg.nix)
│       ├── tmux.nix                # opt-in; ssh-serving hosts flip it
│       ├── home-tools.nix          # programs.home-manager.enable
│       └── hyprland/               # osConfig-gated Hyprland session (1.6)
└── secrets/
    └── README.md                   # placeholder until Phase 3 (sops-nix)
```

### 1.3 `lib/`

**`lib/mkHost.nix`** — curried: flake.nix supplies global args, each host call supplies per-host
args. Relative paths resolve from `lib/`, hence the `../`.

```nix
{
  lib,
  home-manager,
  inputs,
  unstable-overlay,
}:

{
  hostname,
  system ? "x86_64-linux",
  extraModules ? [ ],
}:

lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };

  modules =
    [
      { networking.hostName = hostname; }
      { nixpkgs.overlays = [ unstable-overlay ]; }
      ../modules/nixos
      ../hosts/${hostname}

      home-manager.nixosModules.home-manager
      (
        { config, ... }:
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          # unmanaged files HM takes over get a .backup copy instead of failing activation
          home-manager.backupFileExtension = "backup";
          # user name comes from users.nix's option (lazy evaluation makes this work);
          # username/homeDirectory are pinned to the NixOS user so the HM modules
          # never depend on HM's own defaults
          home-manager.users.${config.cfg.user.name} = {
            imports = [ ../modules/home ];
            home.username = config.cfg.user.name;
            home.homeDirectory = "/home/${config.cfg.user.name}";
          };
          # HM has no home.stateVersion default — set it here, once, per host
          # (first-install marker: do NOT bump it together with the nixpkgs pin)
          home-manager.sharedModules = [ { home.stateVersion = "26.05"; } ];
        }
      )
    ]
    ++ extraModules;
}
```

**`lib/importNixFiles.nix`** — the auto-import primitive. Used by `modules/nixos/default.nix` and
`modules/home/default.nix`, so **dropping a file into a module directory is enough** — no import
lists to edit:

```nix
# Curried: (import ../../lib/importNixFiles.nix) lib ./.   — called from a default.nix
lib: dir:
map (path: import path) (
  lib.filter (
    path:
    lib.hasSuffix ".nix" path
    && baseNameOf path != "default.nix"
    && baseNameOf path != "hardware-configuration.nix"
  ) (lib.filesystem.listFilesRecursive dir)
);
```

`modules/nixos/default.nix` and `modules/home/default.nix` are both just:

```nix
{ lib, ... }:
{
  imports = (import ../../lib/importNixFiles.nix) lib ./.;
}
```

### 1.4 `overlays/unstable.nix`

```nix
# Curried: flake.nix applies `import ./overlays/unstable.nix nixpkgs-unstable`.
# Gives every module (and home-manager module, via useGlobalPkgs) `pkgs.unstable.<pkg>`.
nixpkgs-unstable:
final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev) system;
    config.allowUnfree = true;
  };
}
```

This is the **only** unstable mechanism — do not *also* pass unstable through `specialArgs`.

### 1.5 `modules/nixos/` — system feature modules

Every feature module follows one shape:

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

| File | Option | Enables |
|---|---|---|
| `boot.nix` | `cfg.boot.enable` | systemd-boot (`configurationLimit` ~10 — belt-and-suspenders alongside `nh clean`), `efi.canTouchEfiVariables`, `boot.initrd.systemd.enable`, `boot.tmp.cleanOnBoot`, quiet boot, `zramSwap` |
| `logging.nix` | always on | journald: `storage = "persistent"` (26.05 renamed the old `persistentStorage`; also the default) + size cap (`SystemMaxUse` via `extraConfig`) — unbounded journal is a silent disk-filler |
| `nix.nix` | always on | **Runs Lix** (`nix.package = pkgs.lixPackageSets.latest.lix`), `experimental-features = "nix-command flakes"`, `allowUnfree`, `auto-optimise-store`, trusted users, `nix.registry.nixpkgs` pinned to `inputs.nixpkgs`, `nix.channel.enable = false` + `nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]` (pure-flake hosts carry no channel state; Phase 4's nix-index/comma replaces command-not-found) |
| `nh.nix` | always on (+ `cfg.nh.flakeDir` option) | see [1.8](#18-nh) |
| `locale.nix` | options (always applied) | `cfg.locale.timeZone` (default `"Europe/Warsaw"`), `cfg.locale.defaultLocale` (`"en_US.UTF-8"`), `cfg.locale.keyboard` (`"pl"` — sets both `console.keyMap` and `services.xserver.xkb.layout`; GDM reads the latter) |
| `users.nix` | options | `cfg.user.name` (default `"polishcat"`), `cfg.user.fullName`; creates the normal user with `wheel`, login shell `pkgs.zsh` (matches home-side shell.nix — HM does not set the login shell) with `programs.zsh.enable = true` system-side so the shell is valid (`/etc/shells`); password via `passwd` on first boot (optional `initialHashedPassword` option applied when
  non-null) — **no password = locked account**: key-SSH still works but `sudo`, console and GDM
  login all fail, so a fresh host needs `initialHashedPassword` (or root SSH keys) at first deploy
  (see Phase 2 rollout) |
| `networking.nix` | `cfg.networking.networkManager.enable` (+ `cfg.networking.firewall.enable`, default true) | NetworkManager; firewall on the nftables backend (`networking.nftables.enable`) with per-host allowed ports (+ `networkmanagerapplet` is a home-side concern); `NetworkManager-wait-online` disabled (avoids multi-minute boot stall) |
| `audio.nix` | `cfg.audio.enable` | PipeWire (`alsa`, `pulse`), `security.rtkit.enable` |
| `graphics.nix` | `cfg.graphics.enable` (+ `.enable32Bit`) | `hardware.graphics` OpenGL/VA-API base stack; 32-bit off unless something turns it on (e.g. gaming) |
| `ssh.nix` | `cfg.ssh.enable` (+ `cfg.ssh.port`, default 22; `cfg.ssh.authorizedKeys`, list of strings) | OpenSSH server, password authentication **off**, `authorizedKeys` applied to the main user (without it, keys-only SSH on a fresh host is a lockout), firewall opened on `cfg.ssh.port` |
| `virtualisation.nix` | `cfg.virtualisation.docker.enable`, `cfg.virtualisation.libvirt.enable` | docker (+ `autoPrune` weekly) / libvirtd; an enabled daemon adds `cfg.user.name` to its group; libvirt also pulls `programs.virt-manager` (GUI management) |
| `gaming.nix` | `cfg.gaming.enable` | Steam (`programs.steam` + `gamescopeSession`), `programs.gamemode`, MangoHud (`pkgs.mangohud` — 26.05 dropped the NixOS module), `hardware.xpadneo.enable` (Xbox BT controllers; renamed from `services.hardware.xpadneo`), `mkDefault`s `cfg.graphics.enable32Bit` on |
| `sandbox.nix` | `cfg.sandbox.flatpak.enable`, `cfg.sandbox.firejail.enable` | Flatpak service + Flathub remote bootstrap + Flatseal preinstalled / `programs.firejail` |
| `compat.nix` | `cfg.compat.nix-ld.enable` (+ `.libraries` option), `cfg.compat.envfs.enable`, `cfg.compat.appimage.enable` | run non-Nix binaries/scripts: nix-ld loader shim, envfs FUSE (`/bin`, `/usr/bin` shebangs), AppImage via `programs.appimage` + `binfmt` |
| `desktop/base.nix` | `cfg.desktop.enable` | fonts (`pkgs.nerd-fonts.<font>` + noto — the old monolithic `nerdfonts` package throws at eval), `xdg.portal`, `xdg-user-dirs`; `assertions` guard so at most one DE (`gnome`/`hyprland`/`plasma`) is enabled |
| `desktop/gnome.nix` | `cfg.desktop.gnome.enable` | GNOME (gdm); **sets `cfg.desktop.enable` itself** |
| `desktop/hyprland.nix` | `cfg.desktop.hyprland.enable` | Hyprland launched via uwsm (`programs.hyprland.withUWSM` — activates `graphical-session.target`); `security.polkit`; `security.pam.services.hyprlock` (backs the user-side hyprlock locker); user-side pieces (waybar, hypridle, hyprlock, mako, hyprshot, wallpaper, polkit agent) live in `modules/home/hyprland/`; `mkDefault`s `cfg.graphics/audio` on; **sets `cfg.desktop.enable` itself** |
| `desktop/plasma.nix` | `cfg.desktop.plasma.enable` | KDE Plasma 6 (sddm); **sets `cfg.desktop.enable` itself** |

Option names are quoted for **nixpkgs 26.05** and were verified against the `nixos-26.05` module
sources while implementing (see the implementation notes below the table).

26.05 implementation notes (found while verifying the Phase 1 modules against `nixos-26.05`):

- `services.journald.persistentStorage` is gone — `services.journald.storage = "persistent"`
  (also the default) replaces it
- xpadneo's option moved to `hardware.xpadneo.enable` (was `services.hardware.xpadneo.enable`)
- the NixOS `programs.mangohud` module no longer exists — gaming installs `pkgs.mangohud`
  directly; HM still has `programs.mangohud` if config is wanted later
- `services.flatpak` has no `remotes`/`packages` options on 26.05 — Flathub is bootstrapped by a
  oneshot systemd service and Flatseal lands in `environment.systemPackages`
- `programs.nh.flake` sets `NH_FLAKE`; the bare `FLAKE` variable is deprecated by nh (will hard
  error in future nh releases) — never set both

Example of the DE wiring pattern (`desktop/hyprland.nix`):

```nix
{
  lib,
  config,
  ...
}:
{
  options.cfg.desktop.hyprland.enable = lib.mkEnableOption "Hyprland";

  config = lib.mkIf config.cfg.desktop.hyprland.enable {
    cfg.desktop.enable = true; # pull in fonts/portals/xdg base
    cfg.graphics.enable = lib.mkDefault true;
    cfg.audio.enable = lib.mkDefault true;

    programs.hyprland = {
      enable = true;
      withUWSM = true; # uwsm activates graphical-session.target
    };
    security.polkit.enable = true;
  };
}
```

### 1.6 `modules/home/` — Home Manager modules

Options for home features live in the NixOS tree (`modules/nixos/home-options.nix`), so hosts set
them under the same flat `cfg.*` namespace; the modules themselves are option-less and gate on
`osConfig.cfg.home.*` (all enable flags default to `true` so hosts get a sane user environment for
free):

- `shell.nix` — zsh (autosuggestions, syntaxHighlighting, history opts) + starship + aliases +
  fzf, eza, btop
- `git.nix` — `programs.git` (+ delta, lfs, `init.defaultBranch = "main"`); identity via
  `cfg.home.git.email` / `.name` options
- `terminal.nix` — kitty (font + theme via `settings`)
- `neovim.nix` — `programs.neovim` (`defaultEditor`, `viAlias`, `vimAlias`)
- `xdg.nix` — `xdg.enable`, user dirs, sane mime defaults
- `home-tools.nix` — `programs.home-manager.enable` (HM CLI in the user env)
- `hyprland/` — feature folder (settings/binds, waybar, hypridle, hyprlock, mako, screenshots,
  wallpaper, polkit agent), **no own switch**;
  gated on the *system* switch via `osConfig`. This is the
  worked example of the NixOS ↔ HM bridge:

```nix
{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.desktop.hyprland.enable {
    wayland.windowManager.hyprland.enable = true;
    # keybinds, settings, waybar, launcher...
  };
}
```

GNOME / Plasma home-side config is Phase 4. Existing unmanaged files that HM takes over are
backed up automatically (`home-manager.backupFileExtension = "backup"`, set in `mkHost`) —
never force-overwrite user files.

### 1.7 `hosts/`

`hosts/<name>/default.nix` — self-contained per-host entry: one `cfg = { ... }` tree, sectioned
identity (`user`), locale, git identity (`home.git`), feature
switches, and `nh.flakeDir` pointing at the real repo path on that machine. Hostname is set by
`mkHost`.

`hosts/<name>/hardware-configuration.nix` — **placeholder skeleton**, minimal but valid so
`nix flake check` builds before Phase 2:

```nix
# PLACEHOLDER — replace with real `nixos-generate-config` output on this machine (Phase 2).
{ ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # first-install marker — real nixos-generate-config output sets it too; keep the original value
  system.stateVersion = "26.05";
}
```

Host matrix (the switches each host flips):

| Host | Role | Session | boot | audio | graphics | NetworkManager | ssh | docker | gaming | compat |
|---|---|---|---|---|---|---|---|---|---|---|
| `desktop` | workstation | **Hyprland** | ✓ | ✓ | ✓ | ✓ | ✓ | – | ✓ | ✓ |
| `laptop` | portable | **GNOME** | ✓ | ✓ | ✓ | ✓ | ✓ | – | – | ✓ |
| `server` | headless | none | ✓ | – | – | – | ✓ | ✓ | – | nix-ld only |

`compat` = nix-ld + envfs + AppImage; `server` enables nix-ld only (vscode-server) — envfs and
AppImage are desktop concerns. Foreign-arch binaries (`boot.binfmt.emulatedSystems`, e.g.
aarch64 on desktop) are set per host directly — not a toggle.

### 1.8 nh

`modules/nixos/nh.nix` (always on):

```nix
{
  lib,
  config,
  ...
}:
{
  options.cfg.nh.flakeDir = lib.mkOption {
    type = lib.types.path;
    default = /etc/nixos;
    description = "Where this flake lives on the machine; used by nh and exported as $FLAKE.";
  };

  config = {
    programs.nh = {
      enable = true;
      # sets NH_FLAKE (the bare FLAKE variable is deprecated by nh)
      flake = toString config.cfg.nh.flakeDir;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5";
      };
    };

    # nix.gc.automatic stays off — nh.clean owns garbage collection.
  };
}
```

Result: `nh os switch`, `nh os test`, `nh home switch`, `nh clean` all work from anywhere on the
host, targeting `nixosConfigurations.<hostname>` of this flake.

### 1.9 Root files

- `.gitignore` — `result`, `result-*`, `.direnv/`, `secrets/*` + `!secrets/README.md` (until
  sops-nix replaces it in Phase 3), `*.swp` — the negation keeps the placeholder README
  committable; plain `secrets/` would exclude the whole directory and cannot be re-included
- `.editorconfig` — `[*] utf-8, lf, trim_trailing_whitespace`; `[*.nix] indent_style = space,
  indent_size = 2`
- `secrets/README.md` — states that secrets land here in Phase 3 (sops-nix); nothing sensitive is
  committed before that phase.

### 1.10 Verification strategy

The implementer cannot build locally (no nix on the dev machine). Therefore:

1. Write everything in one pass, then self-review: import paths relative to each file's location,
   every option name, the `cfg.*` namespace consistency.
2. On any Nix machine (or WSL2 with nix): `nix flake check` — the placeholder hardware configs are
   deliberately minimal-but-valid so this passes pre-Phase-2.
3. Same machine: `nixos-rebuild build-vm --flake .#desktop` — boots the full config in QEMU,
   smoke-testing the real module stack (fonts, portals, DE wiring) without touching an actual host.
4. `nix fmt` (the formatter output is part of the scaffold) — clean before every commit.
5. Per real host (Phase 2): swap in real hardware config, then `nh os switch --dry` → `nh os test`
   → `nh os switch`.

### 1.11 Phase 1 acceptance criteria

- [x] `flake.nix` + `lib/` + `overlays/` present; three `nixosConfigurations` declared
- [x] All module files exist and follow the feature-module pattern; no manual import lists outside
      the two `default.nix` importers
- [ ] `nix flake check` passes on a Nix machine (placeholder hardware configs included)
- [ ] `nix fmt` clean
- [x] README host table, PLAN checkboxes, TODO updated

---

## Phase 1.5 — WSL dev host `[ ]`

Promoted from Phase 6: the highest-leverage item — it dissolves the "no nix on the dev machine"
constraint. The WSL distro becomes a fourth host (`wsl`) managed by this flake, and all validation
(`nix flake check`, `nix fmt`, `nix flake update`, `build-vm`) runs locally — including from agent
sessions via `wsl.exe`.

Bootstrap (no chicken-and-egg — the prebuilt tarball needs no repo or nix machine):

- [ ] Import the NixOS-WSL bootstrap tarball from their releases:
      `wsl --import nixos <dir> <tarball>`
- [ ] Inside WSL: clone the repo to `~/nixos-new` — **must live on the Linux side** (`/mnt/c` is
      9p and too slow for nix); edit from Windows via `\\wsl$` / VS Code WSL remote
- [ ] With nix available: run the Phase 1 verification steps ([§1.10](#110-verification-strategy))
      locally instead of on an external machine

Host wiring (once Phase 1 exists):

- [x] Add `nixos-wsl` input (`github:nix-community/NixOS-WSL`, module `nixosModules.wsl`,
      `inputs.nixpkgs.follows = "nixpkgs"`)
- [x] Register `nixosConfigurations.wsl = mkHost { hostname = "wsl"; };`
- [x] `hosts/wsl/default.nix`: import the wsl module, `wsl.enable = true`,
      `wsl.defaultUser = cfg.user.name` (must agree with the user `users.nix` creates); leave
      `boot`/`networking`/`audio`/`graphics` off — WSLg handles graphics/audio on the Windows side,
      NetworkManager is meaningless under WSL NAT; never touch `boot.loader*` inside WSL.
      Always-on `nix`/`nh`/`logging`/`locale`/`users` apply fine
- [x] Set `cfg.nh.flakeDir` to the in-WSL repo path
- [ ] Rewrite AGENTS.md "Environment constraints" + TODO once validation is local

Implementation notes (verified against the NixOS-WSL `main` module sources, 2026-10):

- the module defines no `fileSystems` and disables GRUB — `hosts/wsl/` needs no
  `hardware-configuration.nix` (their own tarball `nixosConfigurations.default` ships none either);
  `system.stateVersion` is set in the host file instead
- their user creation (`isNormalUser`, `uid = mkDefault 1000`, `extraGroups = [ "wheel" ]`) merges
  cleanly with our `users.nix` definition of the same user (list concat, no conflicting leaves)
- the module defaults `security.sudo.wheelNeedsPassword = false` — passwordless sudo works on WSL
  even before a password is set, and `wsl -d <distro> -u root` is always available from Windows;
  the bare-metal locked-account first-deploy rule does not bite here

---

## Phase 2 — Real hardware per host `[ ]`

- [ ] Run `nixos-generate-config` on each machine → replace its placeholder
      `hardware-configuration.nix` (keep the host's `default.nix` wiring intact)
- [ ] `desktop`: import the matching **nixos-hardware** GPU module per `lspci`
      (`common-gpu-nvidia` / `common-gpu-amd` — the module owns `videoDrivers`, modesetting, power
      management; current Hyprland handles the compositor side via explicit sync), finalize gaming
      toggles
- [ ] `laptop`: import the model's **nixos-hardware** module (quirks, firmware, sensors); power
      management (`power-profiles-daemon` or `tlp`), touchpad, firmware updates (`fwupd`)
- [ ] `server`: networking approach (static IP or DHCP reservation; also NetworkManager vs
      `systemd-networkd` — NM is serviceable headless, networkd is the natural server fit),
      fail2ban consideration, monitoring placeholder
- [ ] Disk layout decisions per host (encryption? btrfs/zfs?) — record in ARCHITECTURE.md;
      disko (Phase 6) can make the chosen layout declarative. Disk layout, snapshots, `backup.nix`,
      and impermanence (Phase 6) are one **state-management decision per host** — pick the
      combination together, not independently

**nixos-hardware (all hosts)** — the default mechanism for per-model/per-GPU wiring (driver
modules, quirks, firmware), not a laptop-only candidate. Add the input, then import per host — no
`mkHost` change needed, since `mkHost` already passes `inputs` via `specialArgs`:

```nix
# hosts/<name>/default.nix
imports = [ inputs.nixos-hardware.nixosModules.<model-or-common> ];
```

The pin tracks `master` (no release branches; see decisions log) and is refreshed by the weekly
flake-update cron.

**Rollout order** — server (or a `build-vm` sandbox) first, laptop second, daily-driver desktop
last: the first real deploy exercises the spec on the lowest-stakes machine.

**First deploy, every host** — set `cfg.user.initialHashedPassword` (or enroll the admin key into
root's `openssh.authorizedKeys`) before the first `nh os switch`: with no password set the account
is locked — key-SSH works, but `sudo`, console and GDM login all fail, leaving nothing fixable
remotely.

### 2.1 Standard-defaults modules (all hosts) `[ ]`

Drop-in §1.5-pattern modules; enable per host in `hosts/<name>/default.nix`. Verify option names
against pinned 26.05 at implementation.

- [x] `firmware.nix` — `cfg.firmware.enable`: `services.fwupd` (desktop/laptop/server)
- [x] `storage.nix` — `cfg.storage.enable`: weekly `services.fstrim` + `services.smartd`; add
      `services.btrfs.autoScrub` behind an extra toggle if the disk decision picks btrfs
- [x] `bluetooth.nix` — `cfg.bluetooth.enable`: `hardware.bluetooth` + blueman (desktop/laptop)
- [x] `printing.nix` — `cfg.printing.enable`: CUPS + Avahi discovery + `hardware.sane` scanning
      (desktop/laptop)
- [x] `geolocation.nix` — `cfg.geolocation.enable`: `services.geoclue2` (desktop/laptop — feeds
      gammastep/redshift night light, automatic timezone, map apps)
- [x] `tailscale.nix` — `cfg.tailscale.enable`: `services.tailscale` (desktop/laptop/server; server
      remote access without port-forwarding)
- [x] `syncthing.nix` — `cfg.syncthing.enable`: `services.syncthing` (desktop/laptop/server)
- [ ] `backup.nix` — restic/borg job options — **blocked on Phase 3** (needs sops-nix for
      credentials)

The `wsl` host enables none of these: no real firmware or disks, and the Windows side owns VPN
and networking. 26.05 notes (verified against `nixos-26.05` module sources): `services.avahi`
has no `nssmdns` — the live name is `nssmdns4`/`nssmdns6`; `services.tailscale` owns its firewall
ports via `openFirewall` and `useRoutingFeatures = "client"` relaxes reverse-path filtering;
`services.syncthing` defaults to `overrideDevices`/`overrideFolders = true` — set both `false`
so the Web UI owns devices/folders until they are declared.

Candidate toggles (one service = one module; add on demand, not scheduled):

- **desktop**: `hardware.nvidia` stack (open-kernel-module choice — pending `lspci`),
  `services.ratbag` + piper, `hardware.openrazer` / `hardware.opentabletdriver` (peripheral
  toggles, gaming-adjacent), `programs.kdeconnect`, `virtualisation.waydroid`, Sunshine
  (game-stream host), zen-kernel option on `boot.nix`, `services.ollama` (local LLM host;
  acceleration rides the nvidia/ROCm GPU decision), `services.input-remapper` (keyboard/button
  remapping — ratbag only covers mice), `hardware.keyboard.qmk` / `hardware.keyboard.zsa`
  (custom-keyboard flashing udev rules), `services.usbmuxd` (iPhone pairing/tethering)
- **laptop**: `power.nix` — `services.power-profiles-daemon` vs `services.tlp` vs
  `services.auto-cpufreq` (mutually exclusive, one toggle each), `services.thermald` (Intel),
  `services.fprintd` (fingerprint login; PAM wiring follows), `services.undervolt` /
  `services.throttled` (older-Intel thermal fixes), logind lid-switch handling, Wi-Fi
  powersave / MAC randomization (`networking.networkmanager.wifi.*`), `hardware.sensor.iio`,
  hibernation wiring (the nixos-hardware import itself is the promoted Phase 2 flow above, not a
  candidate toggle)
- **server**: `hardening.nix` (kernel/sysctl baseline), `services.fail2ban` (or a
  `cfg.ssh.fail2ban.enable`), `services.chrony` (NTP; default timesyncd is serviceable),
  `virtualisation.oci-containers`
  (+ rootless `virtualisation.podman` with `dockerCompat` as a docker alternative),
  `services.samba` (+ wsdd) / `services.nfs.server`, `services.caddy` (ACME),
  `services.adguardhome` or `services.blocky`, `services.jellyfin`, monitoring
  (`services.prometheus.exporters.node` + grafana, or `services.netdata`, `services.uptime-kuma`)
  paired with a push-alert channel (ntfy topic / healthchecks.io ping — dashboards alone don't
  page anyone),
  `services.forgejo` / `services.vaultwarden` / `services.paperless` / `services.nextcloud`,
  `services.home-assistant` (long-lived state — pair with the backup decision),
  `services.qbittorrent` (media pipeline with Jellyfin), `services.ddclient` (dynamic DNS —
  Caddy ACME without a static IP), shared backing stores (`services.postgresql`,
  `services.redis`) for the self-hosted apps, initrd network unlock
  (`boot.initrd.network`) if the disk decision picks an encrypted root

## Phase 3 — Secrets (sops-nix) `[ ]`

- [ ] Add `sops-nix` input (follows nixpkgs)
- [ ] Host keys: prefer `sops.age.sshKeyPaths` (derive from each host's existing SSH host key — no
      separate enrollment step); document manual age-identity enrollment only as fallback
- [ ] Back up the master age identity **off-repo** — losing it makes every committed secret
      unrecoverable
- [ ] `.sops.yaml` creation rules; `secrets/*.yaml` committed **encrypted only**
- [ ] `modules/nixos/secrets.nix` behind `cfg.secrets.enable`
- [ ] Add "wire a secret" recipe to AGENTS.md, including the **store-leak rule**: never
      interpolate a decrypted value into a config — anything that lands in the Nix store is
      world-readable. Consumers (NixOS or HM modules) reference the decrypted file via
      `config.sops.secrets.<name>.path`, never the value

## Phase 4 — Per-DE home configs `[ ]`

- [ ] GNOME: dconf-based HM config gated on `osConfig.cfg.desktop.gnome.enable`
- [ ] Plasma: HM config (evaluate the `plasma-manager` input) gated on
      `osConfig.cfg.desktop.plasma.enable`
- [x] Hyprland: expand the Phase 1 example (settings, keybinds, waybar, launcher, idle/lock,
      notification daemon — mako or swaync, screenshots — grim + slurp); also set the
      Electron/Chromium Wayland env vars (`ELECTRON_OZONE_PLATFORM_HINT=auto`, `NIXOS_OZONE_WL=1`)
      so Slack/Discord/VS Code run native — needed on any Wayland session, not just Hyprland.
      *Partly done ahead of Phase 4:* the session runs via uwsm (`programs.hyprland.withUWSM`;
      HM's hyprland systemd integration stays off so user units bind to
      `graphical-session.target`), and `modules/home/hyprland/` ships settings/binds, wofi
      launcher, waybar, hyprpaper wallpaper (`cfg.home.hyprland.wallpaper`), the polkit agent
      (HM `services.hyprpolkitagent`) and the Electron env vars. *Finished:* hypridle
      (`systemdTarget` pinned to `graphical-session.target` since uwsm owns activation) +
      hyprlock (HM `programs.hyprlock`, backed by `security.pam.services.hyprlock` set
      system-side in `desktop/hyprland.nix`), mako notifications, hyprshot screenshot binds
      (Print full screen, $mod+Print region). Only open bit: pick a wallpaper per host

DE-independent home modules (each follows the §1.6 shape; land any time after Phase 1):

- [x] `direnv.nix` — `programs.direnv` + `nix-direnv`; pair with `nix.settings.keep-outputs` /
      `keep-derivations` in `nix.nix` so dev-shell deps survive GC
- [x] `gpg.nix` — `programs.gpg` + `services.gpg-agent` (ssh-agent integration; pairs with
      keys-only ssh). 26.05 HM: pinentry is `services.gpg-agent.pinentry.package` — the flat
      `pinentryPackage` is only a deprecated alias
- [x] `browser.nix` — `programs.firefox` (rides `cfg.desktop.enable`; policies/profiles when
      wanted)
- [x] `ssh.nix` — `programs.ssh` client: per-host aliases, ControlMaster multiplexing, key
      preferences; pairs with the keys-only server in `modules/nixos/ssh.nix`
- [x] `vscode.nix` — `programs.vscode` (rides `cfg.desktop.enable`; extensions stay mutable until
      a declarative extension set is decided; server-side vscode-server is why `server` enables
      nix-ld)
- [x] `easyeffects.nix` — `services.easyeffects` (PipeWire EQ/compressor presets); gated on its
      switch + `cfg.audio` + `cfg.desktop` (26.05 HM wants `programs.dconf.enable` system-side —
      set in `desktop/base.nix`)
- [x] `nix-index.nix` — `programs.nix-index` + comma (channel-less command-not-found)
- [x] CLI modernizers into `shell.nix`: bat, zoxide, atuin, yazi, lazygit, tealdeer
- [ ] Theming: gtk/qt + cursor module; evaluate **Stylix** (single base16 palette across DE,
      terminal, apps) as the heavier alternative
- [x] `tmux.nix` — opt-in (default false); hosts that serve ssh sessions flip it (server does)
- [x] `mpv.nix` — desktop video player (rides `cfg.desktop.enable`)
- [x] `password-store.nix` — `programs.password-store` (pairs with gpg.nix)
- [ ] OBS (desktop) — opt-in screen recording, when wanted
- [ ] HM-side syncthing tray — blocked on Phase 2.1 (`cfg.syncthing.enable`)

## Phase 5 — CI `[ ]`

- [ ] GitHub Actions on push/PR: install nix (DeterminateSystems/nix-installer-action),
      `nix fmt --check`, `nix flake check`
- [ ] CI builds each host's toplevel (`nix build
      .#nixosConfigurations.<host>.config.system.build.toplevel`) — `nix flake check` evaluates
      only; real build breakage should surface on PRs, not on the machines
- [ ] Weekly `nix flake update` cron opening a PR — keeps the 26.05 pin fresh and surfaces nixpkgs
      breakage early
- [ ] Cache strategy (Cachix or GH actions cache) if checks get slow

## Phase 6 — Extras (unscheduled) `[ ]`

- [ ] Installer ISO — deferred; expand the `iso` variant (defaults to
      `installer/cd-dvd/iso-image.nix`, merged via `extendModules`):

  ```nix
  image.modules.iso = { lib, config, pkgs, ... }: {
    # never inherit the host hardware layout (same trick installation-cd-base.nix uses)
    swapDevices = lib.mkImageMediaOverride [ ];
    boot.initrd.luks.devices = lib.mkImageMediaOverride { };

    fileSystems = lib.mkImageMediaOverride (
      config.lib.isoFileSystems or {
        "/" = {
          fsType = "tmpfs";
          options = [ "mode=0755" ];
        };
      }
    );

    isoImage.makeEfiBootable = true;
    isoImage.makeUsbBootable = true;
    # isoImage.makeBiosBootable defaults to true on x86

    isoImage.volumeID = "nixos-nixos-new"; # ≤32 chars; stage 1 mounts the CD by it
    isoImage.configurationName = "nixos-new";
    isoImage.appendToMenuLabel = " Live";
    isoImage.squashfsCompression = "zstd -Xcompression-level 6"; # default is 19
    # isoImage.compressImage = true;                  # whole-ISO zstd → .iso.zst
    # isoImage.includeSystemBuildDependencies = true; # offline installs (large)

    # flake-aware live env (Lix like the hosts)
    # nix.package = pkgs.lixPackageSets.latest.lix;
    # nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # environment.systemPackages = with pkgs; [ git nh vim ];
    # services.openssh.enable = true; # set a root password or key first
  };
  ```

  Variants: `iso` (live media) vs `iso-installer` (`installation-cd-base.nix`: installer
  profiles, git, memtest, `hardware.enableAllHardware`, `live.nixos.passwd=` cmdline
  password). `isoImage.isoName` was renamed → `image.baseName` / `image.fileName` in 25.05.
  Build: `nixos-rebuild build-image --flake .#<host> --image-variant iso` (bare
  `build-image` lists all variants); artifact also at `config.system.build.images.iso`.
- [ ] impermanence (stateless root) — decide per host as part of the Phase 2 state-management
      decision (with disk layout, snapshots, and `backup.nix`), never alone
- [ ] Secure boot via lanzaboote
- [ ] plymouth boot splash
- [ ] colmena / deploy-rs for remote server deploys
- [ ] own binary cache (attic)
- [ ] disko + nixos-anywhere — declarative disk partitioning and hands-off installs from any
      machine (Phase 2 disk decisions then live in the repo, not on the machine)
- [ ] TPM2-backed LUKS auto-unlock (`systemd-cryptenroll`, PCR-bound — meaningful sealing wants
      Secure Boot via lanzaboote)
- [ ] Scheduled auto-updates — systemd timer running `nh os switch` (or `system.autoUpgrade`);
      a deliberate trade-off against the manual nh workflow, decide per host
- [ ] NixOS-WSL host variant — promoted to Phase 1.5

---

## Reference configs

Well-maintained flakes to mine for ideas when implementing a feature (reference, not copy-paste):

- [nixos-hardware](https://github.com/NixOS/nixos-hardware) — per-device quirks (laptop especially)
- [Misterio77/nix-config](https://github.com/Misterio77/nix-config) — mature multi-host layout,
  same mkHost + toggle ideas at scale
- [fufexan/dotfiles](https://github.com/fufexan/dotfiles) — Hyprland + gaming module ideas
- [notashelf/nyx](https://github.com/NotAShelf/nyx) — large toggle-style feature-module config
- [numtide/srvos](https://github.com/numtide/srvos) — opinionated server profiles
- [Stylix](https://github.com/danth/stylix) — cross-DE theming from one base16 palette

---

## Decisions log

| Decision | Choice | Why |
|---|---|---|
| HM integration | NixOS module per host | one `nh os switch` applies OS + user config; standard, least moving parts |
| nixpkgs | stable 26.05 base + unstable overlay | fewer breakages on updates; escape hatch via `pkgs.unstable.<pkg>` |
| Feature toggles | `cfg.*.enable` + `mkIf` | hosts differ (headless vs desktop) without forking modules |
| Unstable mechanism | overlay only | single way to reach unstable; works in HM because `useGlobalPkgs = true` |
| Rebuild tool | nh | simple UX, `FLAKE`-aware, built-in weekly GC via `nh clean` |
| Options namespace | unified `cfg.*` | neutral, greppable, zero collision with upstream options |
| Host assembly | `lib/mkHost.nix` helper | adding a host = one directory + one flake entry; no copy-paste in flake.nix |
| Module discovery | recursive auto-importer | drop-in files; no import lists to maintain |
| Nix implementation | Lix via `nix.package = pkgs.lixPackageSets.latest.lix` | maintained fork with better errors; ships in the pinned nixpkgs — no extra flake input |
| home.stateVersion | set centrally in `mkHost` via `home-manager.sharedModules` | HM has no default; a first-install marker must not follow nixpkgs pin bumps |
| journald | always-on `logging.nix` (persistent storage + size cap) | unbounded journal is a silent disk-filler; identical on every host |
| nixos-hardware | flake input, imported per host via `specialArgs` `inputs` (all hosts, Phase 2) | module collection for per-model/per-GPU wiring — not a package, doesn't violate the unstable-overlay-only rule; tracks `master` (no release branches), refreshed by the weekly flake-update cron |
| Dev-machine validation | NixOS-WSL host (Phase 1.5), bootstrapped from the prebuilt tarball | dissolves the no-nix-on-Windows constraint; repo lives on the WSL Linux filesystem, agent sessions validate via `wsl.exe` |
