# PLAN — nixos-new

> Landed work is ticked and recorded tersely — the code and
> [docs/OPTIONS.md](docs/OPTIONS.md) are the source of truth for what exists; this file is the
> roadmap. Open items are written so an agent or human can execute them without further context.
> Agents: also read [AGENTS.md](AGENTS.md) for conventions and
> [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit together. Immediate tasks
> live in [TODO.md](TODO.md).

## Goal

A single NixOS flake managing every machine from one repo:

- **Multiple hosts** — `desktop`, `laptop`, `server`, `wsl` — assembled by one `mkHost` helper;
  adding a host is one directory + one flake entry.
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
  Validation happens on a nix-capable environment ([§1.10](#110-verification-strategy)); Phase 1.5
  dissolves the constraint locally.
- `flake.lock` is born on the first real `nix flake update` / build; it cannot be generated on the
  dev machine.

## Namespace

All custom options live under one unified `cfg.*` namespace — neutral, greppable, and
collision-free with upstream options (renaming it is one grep-replace). Examples:
`cfg.user.name`, `cfg.nh.flakeDir`, `cfg.desktop.hyprland.enable`, `cfg.audio.enable`.

---

## Phase 1 — Scaffold `[ ]`

Implemented — the checkout is the spec. The phase stays open until machine validation
([§1.10](#110-verification-strategy), [§1.11](#111-phase-1-acceptance-criteria)) passes.

### 1.1 `flake.nix`

Inputs: `nixpkgs` (nixos-26.05), `nixpkgs-unstable` (nixos-unstable), `home-manager`
(release-26.05) — and later additions `nixos-wsl`, `sops-nix`, `plasma-manager`,
`nixos-hardware`, `disko`, `lanzaboote` — all following nixpkgs (lanzaboote deliberately not: it
carries its own nixpkgs to build `lzbt`). Outputs declare one `mkHost` call per host, the
unstable overlay, the `nixfmt-rfc-style` formatter and a dev shell; `inputs@` is bound whole so
modules reach every input through `specialArgs.inputs`.

### 1.2 Folder scheme

The checkout is the live tree; [AGENTS.md](AGENTS.md)'s repo map is the authoritative overview.
In short: `lib/` (mkHost + auto-importer), `overlays/unstable.nix`, `hosts/<name>/` (default.nix +
hardware-configuration.nix + disko.nix), `modules/nixos/` and `modules/home/` (auto-imported
feature modules, with `desktop/` and `hyprland/` subfolders), `scripts/` (disk helpers),
`secrets/` (sops, Phase 3).

### 1.3 `lib/`

- `lib/mkHost.nix` — curried host assembler: flake.nix supplies the global args, each host call
  supplies hostname/system/extraModules. Wires the unstable overlay, both module trees, HM as a
  NixOS module (`useGlobalPkgs`, `useUserPackages`, `backupFileExtension = "backup"`,
  username/homeDirectory pinned to `cfg.user.name`) and passes `inputs` through `specialArgs`.
  `home.stateVersion = "26.05"` is set centrally via `sharedModules` — a first-install marker that
  must not follow nixpkgs pin bumps.
- `lib/importNixFiles.nix` — recursive auto-importer: imports every `.nix` under a directory
  except `default.nix` / `hardware-configuration.nix`; `modules/{nixos,home}/default.nix` call it,
  so dropping a file into a module directory is enough — no import lists to edit.

### 1.4 `overlays/unstable.nix`

Curried overlay giving every module (and HM, via `useGlobalPkgs`) `pkgs.unstable.<pkg>` — the
**only** unstable mechanism; never also pass unstable through `specialArgs`.

### 1.5 `modules/nixos/` — system feature modules

Every feature module is one `mkEnableOption` + `config = lib.mkIf config.cfg.<feature>.enable`
block (full pattern: AGENTS.md checklist). The complete module → option → effect reference is
[docs/OPTIONS.md](docs/OPTIONS.md); option names were verified against the pinned `nixos-26.05`
sources during implementation (the gotchas live as comments in the modules). DE modules
(`desktop/{gnome,hyprland,plasma}.nix`) set `cfg.desktop.enable` themselves and `mkDefault`
graphics/audio — a feature that implies another sets the other's switch (see
`desktop/hyprland.nix`).

### 1.6 `modules/home/` — Home Manager modules

Home-feature options live in the NixOS tree (`modules/nixos/home-options.nix`) so hosts set them
under the same flat `cfg.*` namespace; the modules are option-less and gate on `osConfig.cfg.*`
(all enable flags default **on**). `modules/home/hyprland/` is the worked example of the bridge:
`config = lib.mkIf osConfig.cfg.desktop.hyprland.enable { ... }`.

### 1.7 `hosts/`

`hosts/<name>/default.nix` is self-contained: one `cfg = { ... }` tree, sectioned identity
(`user`), locale, git identity (`home.git`), feature switches, and `cfg.nh.flakeDir` pointing at
the real repo path on that machine. Hostname is set by `mkHost`.

`hosts/<name>/hardware-configuration.nix` — placeholders until Phase 2 swaps in real
`nixos-generate-config` output per host.

| Host | Role | Session |
|---|---|---|
| `desktop` | workstation | Hyprland |
| `laptop` | portable | GNOME |
| `server` | headless | none |
| `wsl` | dev host (Phase 1.5) | WSLg |

Per-host switch wiring: [docs/OPTIONS.md](docs/OPTIONS.md) host matrices. Foreign-arch binaries
(`boot.binfmt.emulatedSystems`) are set per host directly — not a toggle.

### 1.8 nh

`modules/nixos/nh.nix`, always on: `programs.nh` with `flake = toString cfg.nh.flakeDir` (sets
`NH_FLAKE`; the bare `FLAKE` variable is deprecated by nh — never set both) and daily
`nh clean --keep 5 --keep-since 3d`. `nix.gc.automatic` stays off — nh.clean owns GC.

### 1.9 Root files

`.gitignore` (results, `.direnv/`, `secrets/*` with the placeholder README re-included),
`.editorconfig`, `secrets/README.md` (placeholder until Phase 3).

### 1.10 Verification strategy

1. Self-review on the dev machine: import paths relative to each file's location, every option
   name, `cfg.*` namespace consistency.
2. On any Nix machine (or WSL2 with nix): `nix flake check`, `nix fmt` clean before every commit.
3. `nixos-rebuild build-vm --flake .#desktop` — smoke-tests the real module stack (fonts, portals,
   DE wiring) in QEMU without touching an actual host.
4. Per real host (Phase 2): real hardware config in, then `nh os switch --dry` → `nh os test` →
   `nh os switch`.

### 1.11 Phase 1 acceptance criteria

- [x] `flake.nix` + `lib/` + `overlays/` present; three `nixosConfigurations` declared
- [x] All module files exist and follow the feature-module pattern; no manual import lists outside
      the two `default.nix` importers
- [ ] `nix flake check` passes on a Nix machine (placeholder hardware configs included)
- [ ] `nix fmt` clean
- [x] README host table, PLAN checkboxes, TODO updated

---

## Phase 1.5 — WSL dev host `[ ]`

The highest-leverage item — dissolves the "no nix on the dev machine" constraint: the WSL distro
becomes the fourth host (`wsl`), and all validation (`nix flake check`, `nix fmt`,
`nix flake update`, `build-vm`) runs locally, including from agent sessions via `wsl.exe`.

Bootstrap (no chicken-and-egg — the prebuilt image needs no repo or nix machine):

- [ ] Install the NixOS-WSL distro from their releases (checked 2026-10-27: tag 2605.7.2, releases
      ship `.wsl` bundles): `wsl --install --from-file nixos.wsl` (older tarball flow
      `wsl --import nixos <dir> <tarball>` works too)
- [ ] Inside WSL: clone the repo to `~/nixos-new` — **must live on the Linux side** (`/mnt/c` is
      9p and too slow for nix); edit from Windows via `\\wsl$` / VS Code WSL remote
- [ ] Run the [§1.10](#110-verification-strategy) verification steps locally

Host wiring (once Phase 1 exists):

- [x] Add `nixos-wsl` input, register `nixosConfigurations.wsl`, and write
      `hosts/wsl/default.nix`: import the wsl module, `wsl.enable = true`,
      `wsl.defaultUser = cfg.user.name`; leave `boot`/`networking`/`audio`/`graphics` off — WSLg
      handles graphics/audio on the Windows side, NetworkManager is meaningless under WSL NAT;
      never touch `boot.loader*` inside WSL. Always-on `nix`/`nh`/`logging`/`locale`/`users` apply
      fine. `cfg.nh.flakeDir` points at the in-WSL repo path
- [ ] Rewrite AGENTS.md "Environment constraints" + TODO once validation is local

Implementation notes (verified against the NixOS-WSL `main` module sources, 2026-10): the module
defines no `fileSystems` and disables GRUB — `hosts/wsl/` needs no `hardware-configuration.nix`
(`system.stateVersion` is set in the host file); its user creation merges cleanly with ours; it
defaults `security.sudo.wheelNeedsPassword = false`, so the bare-metal locked-account
first-deploy rule does not bite here (`wsl -d <distro> -u root` is always available from Windows).

---

## Phase 2 — Real hardware per host `[ ]`

- [ ] Run `nixos-generate-config` on each machine → replace its placeholder
      `hardware-configuration.nix` (keep the host's `default.nix` wiring intact)
- [ ] `desktop`: import the matching **nixos-hardware** GPU module per `lspci`
      (`common-gpu-nvidia` / `common-gpu-amd` — the module owns `videoDrivers`, modesetting, power
      management), finalize gaming toggles; the `hardware.nvidia` stack choice and initrd
      `amdgpu` ride this
- [ ] `laptop`: import the model's **nixos-hardware** module (quirks, firmware, sensors)
- [ ] `server`: networking approach (static IP or DHCP reservation; NetworkManager vs
      `systemd-networkd` — NM is serviceable headless, networkd is the natural server fit);
      monitoring is wired but dormant (`cfg.monitoring.*`) — pick a service + push-alert channel
      at first deploy (dashboards alone don't page anyone)
- [ ] Disk layout decisions per host — record in ARCHITECTURE.md. Disk layout, snapshots, and
      `backup.nix` are one **state-management decision per host** — pick the combination together,
      not independently (stateless root declined, see Phase 6)

**nixos-hardware (all hosts)** — default mechanism for per-model/per-GPU wiring, imported per
host as `inputs.nixos-hardware.nixosModules.<model-or-common>` (placeholder imports already sit
in each host file; no `mkHost` change needed). The pin tracks `master` (no release branches) and
is refreshed by the weekly flake-update cron.

**Rollout order** — server (or a `build-vm` sandbox) first, laptop second, daily-driver desktop
last: the first real deploy exercises the spec on the lowest-stakes machine.

**First deploy, every host** — set `cfg.user.initialHashedPassword` (or enroll the admin key into
root's `openssh.authorizedKeys`) before the first `nh os switch`: with no password set the account
is locked — key-SSH works, but `sudo`, console and GDM login all fail, leaving nothing fixable
remotely.

### 2.1 Standard-defaults modules (all hosts) `[ ]`

Drop-in §1.5-pattern modules; enable per host in `hosts/<name>/default.nix`. All landed (options
and host wiring: [docs/OPTIONS.md](docs/OPTIONS.md)): `firmware.nix`, `storage.nix`,
`bluetooth.nix`, `printing.nix`, `geolocation.nix`, `tailscale.nix`, `syncthing.nix`,
`backup.nix` (dormant — credentials must be sops-decrypted files, Phase 3), the server trio
`hardening.nix` / `fail2ban.nix` / `monitoring.nix` (server enables hardening + fail2ban;
monitoring dormant, none of it opens the firewall), the laptop batch — `power.nix` (governors
mutually exclusive via assertion, thermald, `cfg.power.lidSwitch`), `fprintd.nix`, Wi-Fi toggles
in `networking.nix` — and the desktop peripheral batch — `ratbagd.nix`, `openrazer.nix`,
`opentabletdriver.nix`, `input-remapper.nix`, `keyboard.nix` (qmk + zsa), `usbmuxd.nix`,
`sunshine.nix`, waydroid in `virtualisation.nix`. The `wsl` host enables none of these (Windows
owns firmware/disks/VPN/networking).

26.05 notes: `services.avahi` has `nssmdns4`/`nssmdns6` (no `nssmdns`); `services.tailscale` owns
its firewall ports via `openFirewall` and `useRoutingFeatures = "client"` relaxes reverse-path
filtering; `services.syncthing` defaults `overrideDevices`/`overrideFolders = true` — set both
`false` so the Web UI owns devices/folders until they are declared.

Remaining candidates (one service = one module; add on demand, not scheduled):

- **desktop**: `hardware.nvidia` stack (open-kernel-module choice — pending `lspci`, Phase 2)
- **laptop**: hibernation wiring, `services.undervolt` / `services.throttled` (older-Intel thermal
  fixes), `hardware.sensor.iio`
- **server**: `services.chrony` (default timesyncd is serviceable), `virtualisation.oci-containers`,
  `services.samba` (+ wsdd) / `services.nfs.server`, `services.caddy` (ACME),
  `services.adguardhome` or `services.blocky`, `services.jellyfin`, `services.forgejo` /
  `vaultwarden` / `paperless` / `nextcloud`, `services.home-assistant` (long-lived state — pair
  with the backup decision), `services.qbittorrent` (media pipeline with Jellyfin),
  `services.ddclient` (dynamic DNS — Caddy ACME without a static IP), shared backing stores
  (`services.postgresql`, `services.redis`), initrd network unlock (`boot.initrd.network`) if the
  disk decision picks an encrypted root

### 2.2 Ports from the legacy `nixos` flake `[ ]`

The superseded legacy flake (`../nixos`, relative to this checkout — hosts pc-main, laptop-main,
server1, vm, vm-desktop) is this repo's direct predecessor; its working configs are the source of
the ports below. All items landed; option names were audited against the pinned nixpkgs 26.05.

Small — edits to existing modules:

- [x] **DoT DNS (systemd-resolved)** — new `modules/nixos/resolved.nix`
      (`cfg.networking.resolved.enable`): DNS-over-TLS with Cloudflare upstreams, LLMNR/mDNS off,
      DNSSEC off. Enabled on desktop, laptop, server — never wsl (Windows owns DNS there).
- [x] **Bluetooth QoL** — `bluetooth.nix`: `settings.General.Experimental` (battery %) +
      `settings.Policy.AutoEnable`.
- [x] **Hyprland cursor theme** — `modules/home/hyprland/cursor.nix`: `home.pointerCursor`
      (adwaita, size 24, gtk enabled) + the uwsm env file `~/.config/uwsm/env-hyprland` setting
      `HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE`.
- [x] **Hyprland tray apps** — `modules/home/hyprland/tray.nix`: nm-applet + pavucontrol.
- [x] **hypridle hardening** — `idle.nix` listener set: `lock_cmd` guards against duplicate
      hyprlock, `before_sleep_cmd = "loginctl lock-session"`, backlight dim at 150 s, lock at
      300 s, dpms off at 330 s, suspend at 900 s.
- [x] **shell.nix utilities** — yt-dlp, ffmpeg, ncdu, duf, unzip, p7zip; case-insensitive zsh
      completion + `cat = bat` alias.
- [x] **nh clean tuning** — daily, `--keep 5 --keep-since 3d` (legacy cadence).
- [x] **git email** — the legacy commit identity on all four hosts; confirm it is the wanted one
      (TODO).

Medium — new modules/options:

- [x] **VS Code declarative config** — `modules/home/vscode.nix`: argv.json, user settings
      (JetBrainsMono font stack) and the extension set — carried entirely by
      `pkgs.vscode-extensions`, no extra flake input. Backed by gnome-keyring (below).
- [x] **Ollama** — `modules/nixos/ollama.nix`: `cfg.ollama.enable` + `cfg.ollama.rocmGfx` (ROCm
      build + gfx override when set). Desktop enables with `rocmGfx = "10.3.0"`. Initrd
      `amdgpu` stays with Phase 2 GPU wiring.
- [x] **Podman option** — `virtualisation.nix`: rootless podman with `dockerCompat` +
      `dockerSocket`, distrobox; assertion keeps it off alongside docker (both own the socket).
      Server stays on docker until a flip is wanted.
- [x] **gnome-keyring** — system-side in `desktop/hyprland.nix` (+ PAM login unlock); backs the
      VS Code `gnome-libsecret` password store. GNOME sessions ship their own.
- [x] **Desktop apps** — `modules/home/desktop-apps.nix`: nemo-with-extensions, gparted, pinta.
- [x] **Gaming apps** — `modules/home/gaming.nix`: prismlauncher, protonup-qt.
- [x] **KDE Connect** — `modules/nixos/kdeconnect.nix` (firewall 1714–1764 TCP+UDP) + HM daemon on
      the same switch. Enabled on desktop, laptop.
- [x] **Boot extras** — `boot.nix`: `cfg.boot.zenKernel.enable`, `cfg.boot.plymouth.enable` +
      theme. Desktop runs zen + plymouth; laptop plymouth only. Legacy Limine entries don't port
      1:1 — memtest86+ (systemd-boot option) and the Windows chainload are decided with real
      hardware configs (Phase 2).
- [x] **Quickshell bar (replaces waybar)** — `modules/home/hyprland/quickshell.nix` + QML vendored
      verbatim into `modules/home/hyprland/quickshell/`; waybar deleted. User unit bound to
      `graphical-session.target` (uwsm-activated); `playerctl` is the only new runtime dep. QML
      hardcodes `BAT1` + 9 workspaces — revisit when the laptop's hardware config lands (Phase 2).
- [x] **Raw Hyprland config (hyprland.lua)** — `session.nix` only enables the HM module; the
      session config is the legacy `hyprland.lua` vendored verbatim (zero Nix interpolation —
      copyable to non-NixOS machines, repo convention). Rofi (vendored `rofi.rasi`) replaced wofi
      to match the lua's SUPER+R bind; `hyprshutdown` backs the SUPER+M bind; Electron/Chromium
      Wayland env vars live in the uwsm env file (Hyprland-scoped — other Wayland sessions would
      need their own). Caveats kept in the lua: monitor workspace mapping targets DP-3/HDMI-A-1;
      Lua config needs Hyprland ≥ 0.53 (26.05 satisfies).

## Phase 3 — Secrets (sops-nix) `[ ]`

- [x] Add `sops-nix` input (follows nixpkgs)
- [x] Host keys: prefer `sops.age.sshKeyPaths` (derive from each host's existing SSH host key — no
      separate enrollment step); document manual age-identity enrollment only as fallback (set
      `sops.age.keyFile` on such hosts)
- [ ] Back up the master age identity **off-repo** — losing it makes every committed secret
      unrecoverable (user action; blocks the next two)
- [x] `.sops.yaml` creation rules (placeholder recipient until the master key exists);
      `secrets/*.yaml` committed **encrypted only** (gitignore allows them, nothing else)
- [x] `modules/nixos/secrets.nix` behind `cfg.secrets.enable` — no host enables it until secrets
      exist
- [x] Add "wire a secret" recipe to AGENTS.md, including the **store-leak rule**: never
      interpolate a decrypted value into a config — anything that lands in the Nix store is
      world-readable. Consumers (NixOS or HM modules) reference the decrypted file via
      `config.sops.secrets.<name>.path`, never the value

## Phase 4 — Per-DE home configs `[ ]`

- [x] GNOME: dconf-based HM config (`modules/home/gnome.nix`) gated on the DE switch — minimal
      sane defaults; extend with more `dconf.settings` entries as preferences emerge
- [x] Plasma: [plasma-manager](https://github.com/nix-community/plasma-manager) (trunk) wired
      dormant (`modules/home/plasma.nix`); `overrideConfig` left unset (default false) so
      user-made KDE settings outside plasma-manager survive. No host enables Plasma yet
- [x] Hyprland: full session shipped in `modules/home/hyprland/` — uwsm activation, vendored
      `hyprland.lua`, rofi launcher, quickshell bar, hypridle + hyprlock (PAM-backed), mako,
      hyprshot binds, hyprpaper, Electron env vars (see §2.2 for the specifics)

DE-independent home modules (each follows the §1.6 shape; all landed — options in
[docs/OPTIONS.md](docs/OPTIONS.md)):

- [x] `direnv.nix` — `programs.direnv` + `nix-direnv`; paired with GC-survivor settings in
      `nix.nix` so dev-shell deps survive GC
- [x] `gpg.nix` — `programs.gpg` + `services.gpg-agent` (ssh-agent integration)
- [x] `browser.nix` — `programs.brave` (swapped from firefox so the lua's SUPER+W
      `brave-browser.desktop` bind resolves)
- [x] `ssh.nix` — ssh client: multiplexing, key preferences; pairs with the keys-only server
- [x] `vscode.nix` — rides `cfg.desktop.enable`
- [x] `easyeffects.nix` — PipeWire EQ; gated on its switch + `cfg.audio` + `cfg.desktop`
- [x] `nix-index.nix` — nix-index + comma (channel-less command-not-found)
- [x] CLI modernizers into `shell.nix`: bat, zoxide, atuin, yazi, lazygit, tealdeer
- [x] `tmux.nix` — opt-in (default false); ssh-serving hosts flip it (server does)
- [x] `mpv.nix` — desktop video player
- [x] `password-store.nix` — `programs.password-store` (pairs with gpg.nix)
- [x] OBS — opt-in: `modules/home/obs.nix` behind `cfg.home.obs.enable` (default off; needs a
      desktop session)
- [x] HM-side syncthing tray — `modules/home/syncthing-tray.nix` on `cfg.syncthing.enable` +
      `cfg.desktop.enable` (quickshell hosts the StatusNotifier icon on hyprland)
- [x] `theming.nix` (rides `cfg.desktop.enable`): HM `dconf.enable` (without it every
      `dconf.settings` is silently dropped), dark gtk + qt adwaita. **Stylix: deferred, then
      resolved (2026-10-28) as runtime theming instead** — see `palette.nix`
- [x] Runtime wallpaper theming (`palette.nix` + `palette/templates/`, behind
      `cfg.home.theming.enable` + a wallpaper): **matugen** (nixpkgs, no new input) extracts a
      Material-You palette from the running wallpaper and renders vendored templates into
      `~/.cache/theming/` — deliberately outside HM management (store symlinks can't be
      overwritten at runtime). **waypaper** (SUPER+SHIFT+W) calls the `wallswitch` script: copy →
      state file `~/.local/state/theming/current` → hyprpaper reload → matugen; the state copy is
      the source of truth (reboots restore the last pick). The default wallpaper
      (`cfg.home.hyprland.wallpaper`) seeds the state file exactly once on first graphical login.
      Theme.qml and the rofi/hyprlock templates consume the palette with hardcoded fallbacks, so
      the vendored-verbatim convention survives; the vendored rasi/hyprlock fonts were swapped
      MesloLGS → JetBrainsMono

## Phase 5 — CI `[ ]`

- [x] GitHub Actions (manual `workflow_dispatch` only — user decision, no push/PR triggers):
      install nix (DeterminateSystems/nix-installer-action), `nix fmt -- --check .`,
      `nix flake check`
- [x] CI builds each host's toplevel (`nix build
      .#nixosConfigurations.<host>.config.system.build.toplevel`, matrix includes `wsl`) — `nix
      flake check` evaluates only; real build breakage should surface in CI, not on the machines
- [x] `nix flake update` opening a PR (manual `workflow_dispatch`, no cron — user decision) —
      keeps the 26.05 pin fresh and surfaces nixpkgs breakage early
- [ ] Cache strategy (Cachix or GH actions cache) if checks get slow

## Phase 6 — Extras (unscheduled) `[ ]`

- [x] Installer ISO (implemented 2026-10-28) — `hosts/installer`: a normal mkHost host that
      builds as an image — GDM Wayland autologin into the repo's Hyprland desktop with the full
      HM session for the profile's passwordless `nixos` user. Imports upstream installer profiles
      via absolute `pkgs.path` references; `disabledModules` drops the channel-era mechanisms
      (the live env is flake-aware via the repo's own nix.nix); no `hardware-configuration.nix`;
      `cfg.boot` stays off (the iso variant owns the loader). Build on a Nix machine:
      `nixos-rebuild build-image --flake .#installer --image-variant iso` (bare `build-image`
      lists variants; artifact also at `config.system.build.images.iso`, which is all CI
      evaluates). Variants: `iso` (live media) vs `iso-installer` (installer profiles +
      `enableAllHardware`); `isoImage.isoName` was renamed → `image.baseName`/`image.fileName`
      in 25.05
- **impermanence (stateless root) — declined** (2026-10-27, user decision): the stateless-root
  workflow doesn't fit how these machines are used; hosts keep a conventional persistent root.
  Preservation was evaluated as the modern alternative — moot with this decision. The Phase 2
  state-management decision per host reduces to disk layout + snapshots + `backup.nix`
- [x] Secure boot via lanzaboote (dormant module, 2026-10-28) —
      `cfg.boot.secureBoot.{enable, autoKeys.enable, measuredBoot.enable}` wrapping their module;
      input pinned to v1.2.0 and deliberately NOT following nixpkgs (26.05 has no `lzbt`; their
      module mkDefaults `boot.lanzaboote.package` to their own nixos-unstable build). Enable-time
      caveats: officially nixos-unstable-only — eval on a Nix machine first; UEFI hardware
      required; pcrlock (measuredBoot) caps boot generations at 4; TPM2-LUKS autoCryptenroll left
      per-host
- [x] plymouth boot splash — ported early as `cfg.boot.plymouth.enable` by §2.2 boot extras
- [ ] colmena / deploy-rs for remote server deploys — deferred (2026-10-28, user decision):
      auto-updates covers server freshness, 4 hosts are cheap to `nh` by hand, and a deployer
      needs a nix-capable machine anyway (WSL pending); colmena costs ~nothing later (deploys
      existing `nixosConfigurations` directly), deploy-rs is one `deploy` output block
- [x] own binary cache (attic) — dormant module (2026-10-28): `cfg.attic.{enable, port,
      environmentFile, settings}` wrapping upstream `services.atticd`; the token must come from a
      sops-decrypted file via `config.sops.secrets.<name>.path` (store-leak rule — asserted at
      eval time). Enabling waits on the Phase 3 sops key
- [x] disko + nixos-hardware per host (2026-10-28) — `hosts/<host>/disko.nix` with Btrfs-on-LUKS
      layouts (desktop: single cryptroot; laptop: cryptroot + swapfile; server: cryptroot +
      separate cryptdata for /var/lib/docker, syncthing, backups). nixos-hardware placeholder
      imports in each host's default.nix. `scripts/nixos-disk` for manual partitioning,
      `nixos-mount`/`umount`/`format-part` for install-time mounting. `REPLACE_WITH_DISK_ID` and
      real model modules pending per host; nixos-anywhere usage still open
- [ ] TPM2-backed LUKS auto-unlock (`systemd-cryptenroll`, PCR-bound — meaningful sealing wants
      Secure Boot via lanzaboote) — 2026-10-28: groundwork landed (`secure-boot.nix`
      measuredBoot = systemd-pcrlock PCR policy); disko layouts include LUKS label `cryptroot`
      for autoCryptenroll; per-host `keyFile` + `cfg.boot.secureBoot.measuredBoot.autoCryptenroll`
      stays open
- [x] Scheduled auto-updates (module dormant, 2026-10-28) — `cfg.updates.auto.{enable, dates,
      operation, allowReboot}` wraps upstream `system.autoUpgrade` flake-aware (flake =
      `cfg.nh.flakeDir`); the per-host enablement trade-off against the manual nh workflow stays
      open
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
| Installer ISO | `nixosConfigurations.installer` — a mkHost host that builds as an image | upstream's `build-image --image-variant` needs a nixosConfiguration ref; assembling via mkHost keeps one host-assembly path and gives the live env the full HM Hyprland session (2026-10-28) |
| Secure Boot input | lanzaboote pinned v1.2.0, deliberately not following nixpkgs | `lzbt` is absent from 26.05; their module mkDefaults `boot.lanzaboote.package` to a build from the nixos-unstable nixpkgs the input carries itself (2026-10-28) |
| Deploy tooling (colmena / deploy-rs) | deferred (2026-10-28, user decision) | auto-updates covers server freshness; 4 hosts are cheap to `nh` by hand; a deployer needs a nix-capable machine anyway (WSL pending); adding colmena later costs ~nothing |
| Disk layout | Btrfs-on-LUKS via Disko per host (2026-10-28) | desktop/laptop: single cryptroot; server: cryptroot + cryptdata for /var/lib; enables nixos-anywhere + TPM2-LUKS autoCryptenroll |
| nixos-hardware | per-host placeholder imports (2026-10-28) | replace with actual device model modules when hardware is known |
| Stateless root | declined — impermanence (and the preservation alternative) stay out | the stateless-root workflow doesn't fit the user's workflow; hosts keep a conventional persistent root (2026-10-27) |
