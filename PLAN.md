# PLAN — nixos-new

> **Status:** Phase 1 (scaffold) is fully specified but **not yet implemented**. Every phase below
> is written so an agent or human can execute it without further context. Agents: also read
> [AGENTS.md](AGENTS.md) for conventions and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how
> the pieces fit together. Immediate tasks live in [TODO.md](TODO.md).

## Goal

A single NixOS flake managing every machine from one repo:

- **Multiple hosts** — `desktop`, `laptop`, `server` — assembled by one `mkHost` helper; adding a
  host is one directory + one flake entry.
- **Home Manager** integrated as a NixOS module per host, so a single `nh os switch` applies OS and
  user configuration together.
- **Toggleable feature modules** — every feature (desktop environments, audio, gaming, docker, ssh,
  …) sits behind a `cfg.*.enable` option; hosts flip switches, modules stay machine-agnostic.
- **Stable base + unstable on tap** — `nixpkgs` 25.05 is primary; unstable reachable everywhere as
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Outputs (sketch):

```nix
outputs =
  { self, nixpkgs, nixpkgs-unstable, home-manager }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    inputs = { inherit nixpkgs nixpkgs-unstable home-manager; };
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
├── .gitignore                      # result*, .direnv/, secrets/ (until Phase 3)
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
│   └── installer/default.nix        # live-ISO config, not a deployable host (§1.9)
├── modules/
│   ├── nixos/
│   │   ├── default.nix             # auto-imports every sibling .nix
│   │   ├── boot.nix                # systemd-boot, EFI vars, silent boot, zram
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
│   │   └── desktop/
│   │       ├── base.nix            # cfg.desktop.enable: fonts, portals, xdg
│   │       ├── gnome.nix
│   │       ├── hyprland.nix
│   │       └── plasma.nix
│   └── home/
│       ├── default.nix             # auto-imports every sibling .nix
│       ├── shell.nix               # zsh + starship + aliases
│       ├── git.nix                 # programs.git; email via option
│       ├── terminal.nix            # kitty
│       ├── neovim.nix              # base programs.neovim
│       └── hyprland.nix            # osConfig-gated example (1.6)
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
          # user name comes from users.nix's option (lazy evaluation makes this work)
          home-manager.users.${config.cfg.user.name} = import ../modules/home;
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
    baseNameOf path != "default.nix" && baseNameOf path != "hardware-configuration.nix"
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
| `boot.nix` | `cfg.boot.enable` | systemd-boot, `efi.canTouchEfiVariables`, quiet boot, `zramSwap` |
| `nix.nix` | always on | **Runs Lix** (`nix.package = pkgs.lixPackageSets.latest.lix`), `experimental-features = "nix-command flakes"`, `allowUnfree`, `auto-optimise-store`, trusted users, `nix.registry.nixpkgs` pinned to `inputs.nixpkgs` |
| `nh.nix` | always on (+ `cfg.nh.flakeDir` option) | see [1.8](#18-nh) |
| `locale.nix` | options (always applied) | `cfg.locale.timeZone` (default `"Europe/Warsaw"`), `cfg.locale.defaultLocale` (`"en_US.UTF-8"`), `cfg.locale.keyboard` (`"pl"`) |
| `users.nix` | options | `cfg.user.name` (default `"polishcat"`), `cfg.user.fullName`; creates the normal user with `wheel`; password via `passwd` on first boot (optional `initialHashedPassword` option applied when non-null) |
| `networking.nix` | `cfg.networking.networkManager.enable` | NetworkManager (+ `networkmanagerapplet` is a home-side concern) |
| `audio.nix` | `cfg.audio.enable` | PipeWire (`alsa`, `pulse`), `security.rtkit.enable` |
| `graphics.nix` | `cfg.graphics.enable` (+ `.enable32Bit`) | `hardware.graphics` OpenGL/VA-API base stack; 32-bit off unless something turns it on (e.g. gaming) |
| `ssh.nix` | `cfg.ssh.enable` | OpenSSH server, password authentication **off** |
| `virtualisation.nix` | `cfg.virtualisation.docker.enable`, `cfg.virtualisation.libvirt.enable` | docker / libvirtd |
| `gaming.nix` | `cfg.gaming.enable` | Steam (`programs.steam` + `gamescopeSession`), `programs.gamemode`, MangoHud, `services.hardware.xpadneo` (Xbox BT controllers), `mkDefault`s `cfg.graphics.enable32Bit` on |
| `sandbox.nix` | `cfg.sandbox.flatpak.enable`, `cfg.sandbox.firejail.enable` | Flatpak service + Flathub remote bootstrap + Flatseal preinstalled / `programs.firejail` |
| `desktop/base.nix` | `cfg.desktop.enable` | fonts (nerdfonts + noto), `xdg.portal`, `xdg-user-dirs` |
| `desktop/gnome.nix` | `cfg.desktop.gnome.enable` | GNOME (gdm); **sets `cfg.desktop.enable` itself** |
| `desktop/hyprland.nix` | `cfg.desktop.hyprland.enable` | Hyprland; also `security.polkit`, and `mkDefault`s `cfg.graphics/audio` on; **sets `cfg.desktop.enable` itself** |
| `desktop/plasma.nix` | `cfg.desktop.plasma.enable` | KDE Plasma 6 (sddm); **sets `cfg.desktop.enable` itself** |

Option names are quoted for **nixpkgs 25.05**. When implementing, verify against the pinned
nixpkgs (grep the store path on a Nix machine, or search.nixos.org for the pinned release).

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

    programs.hyprland.enable = true;
    security.polkit.enable = true;
  };
}
```

### 1.6 `modules/home/` — Home Manager modules

Same option-gated shape as system modules (`cfg.home.<feature>.enable`, all defaulting to
`true` so hosts get a sane user environment for free):

- `shell.nix` — zsh + starship + aliases
- `git.nix` — `programs.git`; identity via `cfg.home.git.email` / `.name` options
- `terminal.nix` — kitty
- `neovim.nix` — base `programs.neovim`
- `hyprland.nix` — **no own switch**; gated on the *system* switch via `osConfig`. This is the
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

GNOME / Plasma home-side config is Phase 4.

### 1.7 `hosts/`

`hosts/<name>/default.nix` — per-host entry: flips feature switches, overrides user/locale options,
sets `cfg.nh.flakeDir` to the real repo path on that machine. Hostname is set by `mkHost`.

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
}
```

Host matrix (the switches each host flips):

| Host | Role | Session | boot | audio | graphics | NetworkManager | ssh | docker | gaming |
|---|---|---|---|---|---|---|---|---|---|
| `desktop` | workstation | **Hyprland** | ✓ | ✓ | ✓ | ✓ | ✓ | – | ✓ |
| `laptop` | portable | **GNOME** | ✓ | ✓ | ✓ | ✓ | ✓ | – | – |
| `server` | headless | none | ✓ | – | – | – | ✓ | ✓ | – |

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
      flake = config.cfg.nh.flakeDir;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5";
      };
    };

    environment.variables.FLAKE = toString config.cfg.nh.flakeDir;
    # nix.gc.automatic stays off — nh.clean owns garbage collection.
  };
}
```

Result: `nh os switch`, `nh os test`, `nh home switch`, `nh clean` all work from anywhere on the
host, targeting `nixosConfigurations.<hostname>` of this flake.

### 1.9 Root files

- `.gitignore` — `result`, `result-*`, `.direnv/`, `secrets/*` (until sops-nix replaces it in
  Phase 3), `*.swp`
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
3. `nix fmt` (the formatter output is part of the scaffold) — clean before every commit.
4. Per real host (Phase 2): swap in real hardware config, then `nh os switch --dry` → `nh os test`
   → `nh os switch`.

### 1.11 Phase 1 acceptance criteria

- [ ] `flake.nix` + `lib/` + `overlays/` present; three `nixosConfigurations` declared
- [ ] All module files exist and follow the feature-module pattern; no manual import lists outside
      the two `default.nix` importers
- [ ] `nix flake check` passes on a Nix machine (placeholder hardware configs included)
- [ ] `nix fmt` clean
- [ ] README host table, PLAN checkboxes, TODO updated

---

## Phase 2 — Real hardware per host `[ ]`

- [ ] Run `nixos-generate-config` on each machine → replace its placeholder
      `hardware-configuration.nix` (keep the host's `default.nix` wiring intact)
- [ ] `desktop`: GPU driver specifics per `lspci` (NVIDIA vs AMD), finalize gaming toggles
- [ ] `laptop`: power management (`power-profiles-daemon` or `tlp`), touchpad, firmware updates
      (`fwupd`)
- [ ] `server`: networking approach (static IP or DHCP reservation), fail2ban consideration,
      monitoring placeholder
- [ ] Disk layout decisions per host (encryption? btrfs/zfs?) — record in ARCHITECTURE.md

## Phase 3 — Secrets (sops-nix) `[ ]`

- [ ] Add `sops-nix` input (follows nixpkgs)
- [ ] age key per host; `.sops.yaml` creation rules; `secrets/*.yaml` committed **encrypted only**
- [ ] `modules/nixos/secrets.nix` behind `cfg.secrets.enable`
- [ ] Add "wire a secret" recipe to AGENTS.md

## Phase 4 — Per-DE home configs `[ ]`

- [ ] GNOME: dconf-based HM config gated on `osConfig.cfg.desktop.gnome.enable`
- [ ] Plasma: HM config (evaluate the `plasma-manager` input) gated on
      `osConfig.cfg.desktop.plasma.enable`
- [ ] Hyprland: expand the Phase 1 example (settings, keybinds, waybar, launcher, idle/lock)

## Phase 5 — CI `[ ]`

- [ ] GitHub Actions on push/PR: install nix (DeterminateSystems/nix-installer-action),
      `nix fmt --check`, `nix flake check`
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
- [ ] impermanence (stateless root) — decide per host
- [ ] Secure boot via lanzaboote
- [ ] plymouth boot splash
- [ ] colmena / deploy-rs for remote server deploys
- [ ] own binary cache (attic)

---

## Decisions log

| Decision | Choice | Why |
|---|---|---|
| HM integration | NixOS module per host | one `nh os switch` applies OS + user config; standard, least moving parts |
| nixpkgs | stable 25.05 base + unstable overlay | fewer breakages on updates; escape hatch via `pkgs.unstable.<pkg>` |
| Feature toggles | `cfg.*.enable` + `mkIf` | hosts differ (headless vs desktop) without forking modules |
| Unstable mechanism | overlay only | single way to reach unstable; works in HM because `useGlobalPkgs = true` |
| Rebuild tool | nh | simple UX, `FLAKE`-aware, built-in weekly GC via `nh clean` |
| Options namespace | unified `cfg.*` | neutral, greppable, zero collision with upstream options |
| Host assembly | `lib/mkHost.nix` helper | adding a host = one directory + one flake entry; no copy-paste in flake.nix |
| Module discovery | recursive auto-importer | drop-in files; no import lists to maintain |
| Nix implementation | Lix via `nix.package = pkgs.lixPackageSets.latest.lix` | maintained fork with better errors; ships in the pinned nixpkgs — no extra flake input |
