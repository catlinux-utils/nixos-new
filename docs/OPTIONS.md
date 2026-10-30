# Options — the complete `cfg.*` reference

Every knob a host can set, in one place. Options are declared in the NixOS module tree
(`modules/nixos/**/*.nix`, grouped into category folders — folder membership is tree organisation
only, options stay in the flat `cfg.*` tree; home-feature options in
`modules/nixos/home-options.nix`) and hosts set
them in `hosts/<name>/default.nix` under the flat `cfg.*` tree.

Conventions: feature switches are `lib.mkEnableOption` → **default off**; hosts flip them.
Home-feature options default **on** unless noted (a sane user environment for free). To
re-derive this list: `grep -rn "options.cfg" modules/nixos/`. The installer ISO
(`hosts/installer/default.nix`) consumes options too — Hyprland desktop + theming +
NetworkManager/resolved, `cfg.boot` deliberately off (the ISO variant owns the loader) — but
it's an image, so it isn't in the host matrices.

## Always on (no switch)

These modules apply on every host — only their value options are configurable:

| Module | Options (type, default) | Effect |
|---|---|---|
| `logging.nix` | — | journald: persistent storage + size cap |
| `nix.nix` | — | Lix, flakes, allowUnfree, store optimisation, pinned registry, no channels, GC-survivor settings for direnv |
| `nh.nix` | `cfg.nh.flakeDir` (path, `/etc/nixos`) | `nh` CLI + daily GC (`--keep 5 --keep-since 3d`); flake path via `NH_FLAKE` |
| `locale.nix` | `cfg.locale.timeZone` (str, `Europe/Warsaw`) · `cfg.locale.defaultLocale` (str, `en_US.UTF-8`) · `cfg.locale.keyboard` (str, `pl`) | timezone, locale set, console + X/Wayland keymap |
| `users.nix` | `cfg.user.name` (str, `cat`) · `cfg.user.fullName` (str, `ThePolishcat`) · `cfg.user.initialHashedPassword` (nullOr str, `null`) | creates the main user (wheel, zsh login shell); password only for first deploy |

## System feature switches

Default off unless noted. "On" = hosts currently setting it.

| Option | Turns on | desktop | laptop | server | wsl |
|---|---|:---:|:---:|:---:|:---:|
| `cfg.boot.enable` | systemd-boot, EFI vars, silent boot, zram | ✓ | ✓ | ✓ | – (WSL owns boot) |
| `cfg.boot.zenKernel.enable` | zen kernel (`linuxPackages_zen`) | ✓ | – | – | – |
| `cfg.boot.plymouth.enable` | Plymouth boot splash (theme: `cfg.boot.plymouth.theme`) | ✓ | ✓ | – | – |
| `cfg.networking.networkManager.enable` | NetworkManager | ✓ | ✓ | – | – |
| `cfg.networking.firewall.enable` (default **on**) | nftables firewall; ports via sub-options below | ✓ | ✓ | ✓ | ✗ (set false — Windows filters) |
| `cfg.networking.resolved.enable` | systemd-resolved with DNS-over-TLS (Cloudflare upstreams) | ✓ | ✓ | ✓ | – |
| `cfg.audio.enable` | PipeWire + rtkit | ✓ | ✓ | – | – (WSLg) |
| `cfg.graphics.enable` | OpenGL/VA-API base stack | ✓ | ✓ | – | – |
| `cfg.ssh.enable` | OpenSSH, keys only | ✓ | ✓ | ✓ | – |
| `cfg.virtualisation.docker.enable` | Docker + weekly auto-prune, docker group | – | – | ✓ | – |
| `cfg.virtualisation.podman.enable` | rootless Podman + docker-compatible socket, distrobox; assertion: not together with docker | – | – | – | – |
| `cfg.virtualisation.libvirt.enable` | libvirtd + virt-manager, libvirtd group | – | – | – | – |
| `cfg.virtualisation.waydroid.enable` | Waydroid Android container (upstream auto-picks the nftables flavor under our nftables firewall) — dormant | – | – | – | – |
| `cfg.gaming.enable` | Steam + gamescope, GameMode, MangoHud, xpadneo; mkDefaults `graphics.enable32Bit` | ✓ | – | – | – |
| `cfg.ollama.enable` | Ollama local-LLM server (ROCm build when `rocmGfx` is set) | ✓ | – | – | – |
| `cfg.kdeconnect.enable` | KDE Connect package + firewall 1714–1764; the HM daemon rides the same switch | ✓ | ✓ | – | – |
| `cfg.sandbox.flatpak.enable` | Flatpak + Flathub bootstrap + Flatseal | – | – | – | – |
| `cfg.sandbox.firejail.enable` | Firejail | – | – | – | – |
| `cfg.compat.nix-ld.enable` | nix-ld loader shim | ✓ | ✓ | ✓ | ✓ |
| `cfg.compat.envfs.enable` | envfs FUSE (`/bin`, `/usr/bin` shebangs) | ✓ | ✓ | – | – |
| `cfg.compat.appimage.enable` | AppImage via binfmt | ✓ | ✓ | – | – |
| `cfg.firmware.enable` | fwupd | ✓ | ✓ | ✓ | – |
| `cfg.storage.enable` | weekly fstrim + smartd | ✓ | ✓ | ✓ | – |
| `cfg.bluetooth.enable` | bluez (battery reporting, auto-enable) + blueman applet | ✓ | ✓ | – | – |
| `cfg.printing.enable` | CUPS + Avahi mDNS + SANE (scanner/lp groups) | ✓ | ✓ | – | – |
| `cfg.geolocation.enable` | geoclue2 (night light, auto timezone) | ✓ | ✓ | – | – |
| `cfg.tailscale.enable` | tailscaled (mesh client; `tailscale up` once per host) | ✓ | ✓ | ✓ | – |
| `cfg.syncthing.enable` | syncthing as the main user (Web UI on 127.0.0.1:8384) | ✓ | ✓ | ✓ | – |
| `cfg.hardening.enable` | kernel/sysctl baseline (kptr/dmesg/bpf/ptrace/redirects/protected_*) + `security.sudo.execWheelOnly` — server-oriented, not for dev hosts | – | – | ✓ | – |
| `cfg.fail2ban.enable` | fail2ban — upstream attaches its sshd jail when `cfg.ssh.enable`, reads the journal, nftables banaction; escalating bantime | – | – | ✓ | – |
| `cfg.monitoring.nodeExporter.enable` | Prometheus node exporter (port 9100, firewall stays closed — scrape over Tailscale) — dormant | – | – | – | – |
| `cfg.monitoring.netdata.enable` | Netdata real-time dashboard (port 19999, firewall stays closed) — dormant | – | – | – | – |
| `cfg.monitoring.uptimeKuma.enable` | Uptime Kuma (localhost:3001; built-in notifiers cover ntfy/healthchecks-style push) — dormant | – | – | – | – |
| `cfg.power.powerProfiles.enable` / `.tlp.enable` / `.autoCpufreq.enable` | the three power governors — mutually exclusive (assertion; upstream also asserts ppd vs the others; GNOME hosts mkDefault ppd on) — dormant | – | – | – | – |
| `cfg.power.thermald.enable` | Intel thermal management daemon — dormant | – | – | – | – |
| `cfg.fprintd.enable` | fprintd fingerprint login — PAM picks it up automatically (`fprintAuth` defaults to the daemon switch; enroll with `fprintd-enroll`) — dormant | – | – | – | – |
| `cfg.ratbagd.enable` | ratbagd (gaming-mouse daemon) + piper GUI — upstream renamed `services.ratbag` → `services.ratbagd` — dormant | – | – | – | – |
| `cfg.openrazer.enable` | OpenRazer daemon (user service; main user wired into its device group) — dormant | – | – | – | – |
| `cfg.opentabletdriver.enable` | OpenTabletDriver (udev rules + user service; upstream blacklists the conflicting wacom/hid-uclogic kernel modules) — dormant | – | – | – | – |
| `cfg.inputRemapper.enable` | input-remapper daemon + GTK GUI (upstream keeps udev hotplug rules off by default) — dormant | – | – | – | – |
| `cfg.keyboard.qmk.enable` / `.zsa.enable` | keyboard flashing udev rules (QMK: Keychron via `.keychronSupport`; ZSA: ErgoDox EZ/Planck EZ/Moonlander) — dormant | – | – | – | – |
| `cfg.usbmuxd.enable` | usbmuxd + libimobiledevice CLI (iPhone/iPad USB pairing, tethering) — dormant | – | – | – | – |
| `cfg.sunshine.enable` | Sunshine game-stream host (user service on graphical-session.target, avahi discovery, uinput; LAN ports opened via mkDefault — override per host) — dormant | – | – | – | – |
| `cfg.backup.enable` | restic + borg job passthroughs (dormant — credentials wait on the Phase 3 sops key) | – | – | – | – |
| `cfg.secrets.enable` | sops-nix defaults (age via SSH host key, `secrets/secrets.yaml`); needs the master age identity set up first (see `.sops.yaml`) | – | – | – | – |
| `cfg.updates.auto.enable` | scheduled flake-aware auto-updates (`system.autoUpgrade` pulls the flake at `cfg.nh.flakeDir`) — dormant | – | – | – | – |
| `cfg.boot.secureBoot.enable` | Secure Boot via lanzaboote, signed systemd-boot — dormant (officially nixos-unstable-only; eval on a Nix machine before enabling) | – | – | – | – |
| `cfg.attic.enable` | attic binary-cache server (`services.atticd`) — dormant, needs a sops secret first | – | – | – | – |

### Disk layouts (Disko, per host)

Each host has a `hosts/<host>/disko.nix` defining a Btrfs-on-LUKS layout:

| Host | Layout |
|---|---|
| `desktop` | Single `cryptroot` (100% disk) → Btrfs subvolumes `@`, `@home`, `@snapshots`, `@log`, `@nix` |
| `laptop` | Single `cryptroot` (100% disk) → same subvolumes; swapfile on `@root` for hibernation |
| `server` | `cryptroot` (100G) → root subvolumes; `cryptdata` (rest) → Btrfs subvolumes `docker`, `containers`, `syncthing`, `backups`, `libvirt` mounted under `/var/lib` |

Replace `REPLACE_WITH_DISK_ID` with the target disk's `/dev/disk/by-id/...` path.

### Sub-options (set per host when needed)

| Option | Type, default | Purpose |
|---|---|---|
| `cfg.networking.firewall.allowedTCPPorts` / `.allowedUDPPorts` | listOf port, `[]` | per-host firewall openings |
| `cfg.ssh.port` | port, `22` | SSH listen port |
| `cfg.ssh.authorizedKeys` | listOf str, `[]` | keys for the main user — **required on a fresh keys-only host** |
| `cfg.fail2ban.ignoreIP` | listOf str, `[]` | IPs/CIDRs fail2ban never bans (upstream whitelists loopback already) |
| `cfg.networking.wifi.powersave.enable` / `.macRandomization.enable` | bool, off (ride `cfg.networking.networkManager.enable`) | Wi-Fi power saving · stable per-network random MAC (scanning randomized upstream already) |
| `cfg.graphics.enable32Bit` | bool (mkEnableOption → off; `gaming` mkDefaults it on) | 32-bit GL for Steam |
| `cfg.ollama.rocmGfx` | nullOr str, `null` | AMD GFX override (e.g. `"10.3.0"`); null = stock ollama |
| `cfg.boot.plymouth.theme` | str, `tribar` | Plymouth theme name |
| `cfg.power.lidSwitch` | nullOr enum (logind.conf(5) actions: ignore/poweroff/reboot/halt/kexec/suspend/hibernate/hybrid-sleep/suspend-then-hibernate/lock), `null` | `HandleLidSwitch` override — null = upstream default (suspend). 26.05 name: `services.logind.settings.Login.HandleLidSwitch` (`extraConfig` removed) |
| `cfg.compat.nix-ld.libraries` | listOf package, `[]` | libs for non-Nix binaries |
| `cfg.backup.restic.jobs` | attrsOf anything, `{}` | assigned to `services.restic.backups` (26.05-verified fields); credentials via `config.sops.secrets.<name>.path` |
| `cfg.backup.borg.jobs` | attrsOf anything, `{}` | assigned to `services.borgbackup.jobs`; secrets via `passCommand`/`environment` referencing sops files, never values |
| `cfg.user.initialHashedPassword` | nullOr str, `null` | first-deploy password — locked account without it (see PLAN Phase 2) |
| `cfg.updates.auto.dates` / `.operation` / `.allowReboot` | str, `04:40` · enum `switch|boot`, `switch` · bool, off | timer schedule · switch vs stage-for-reboot · reboot consent |
| `cfg.boot.secureBoot.autoKeys.enable` / `.measuredBoot.enable` | bool, off | auto-generate + auto-enroll the sbctl key bundle into firmware NVRAM · systemd-pcrlock PCR policy (caps boot generations at 4) |
| `cfg.attic.port` / `.environmentFile` / `.settings` | port, `8080` · nullOr path, `null` (required when enabled) · attrs, `{}` | listen port (firewall-opened) · sops-decrypted env file — `config.sops.secrets.<name>.path`, never a value · settings.toml passthrough |
| `cfg.home.theming.enable` / `.wallpapers` (laptop) | bool, off · listOf path | runtime theming for GNOME: matugen palette from wallpaper → GTK/Qt/bar/mako/kitty/hyprlock; wallpapers installed to `~/Pictures/Wallpapers/` |

## Desktop session

One DE per host — an assertion makes two enabled DEs fail evaluation. DE modules set
`cfg.desktop.enable` themselves (fonts, portals, dconf, xdg base) and `mkDefault` graphics/audio.

| Option | Turns on | desktop | laptop | server | wsl |
|---|---|:---:|:---:|:---:|:---:|
| `cfg.desktop.gnome.enable` | GNOME (GDM) | – | ✓ | – | – |
| `cfg.desktop.hyprland.enable` | Hyprland via uwsm (+ PAM hyprlock + the UWSM wayland-session entry for display managers); config = vendored `hyprland.lua` + rofi, not generated | ✓ | – | – | – |
| `cfg.desktop.plasma.enable` | KDE Plasma 6 (SDDM) | – | – | – | – |

## Home options (`cfg.home.*`)

Declared in `modules/nixos/home-options.nix`; the option-less modules in `modules/home/` gate on
them via `osConfig`. All default **true** except where noted. Modules with **no option** ride
system switches instead: `browser.nix`, `vscode.nix`, `desktop-apps.nix`, `theming.nix`,
`mpv.nix` and `easyeffects.nix` require `cfg.desktop.enable` (easyeffects also
`cfg.audio.enable`; vscode configures settings/extensions declaratively; theming enables HM
`dconf` and sets dark gtk + qt adwaita for every desktop), `gaming.nix` on `cfg.gaming.enable`,
`kdeconnect.nix` on `cfg.kdeconnect.enable`, `gnome.nix` on `cfg.desktop.gnome.enable`,
`plasma.nix` on `cfg.desktop.plasma.enable` (also imports the plasma-manager HM module, inert
without the switch), `syncthing-tray.nix` on `cfg.syncthing.enable` + `cfg.desktop.enable`,
`palette.nix` on `cfg.desktop.enable` + `cfg.home.theming.enable` + a wallpaper being set, and
the `hyprland/` folder on `cfg.desktop.hyprland.enable`.

| Option | Type, default | Effect |
|---|---|---|
| `cfg.home.shell.enable` | bool, on | zsh + starship + fzf/eza/btop/bat/zoxide/atuin/yazi/lazygit/tealdeer + yt-dlp/ffmpeg/ncdu/duf/zip utilities |
| `cfg.home.git.enable` | bool, on | git + delta + lfs, `init.defaultBranch = main` |
| `cfg.home.git.name` / `.email` | nullOr str, `null` | git identity (null = unset) |
| `cfg.home.terminal.enable` | bool, on | kitty |
| `cfg.home.neovim.enable` | bool, on | neovim as default editor, vi/vim aliases |
| `cfg.home.xdg.enable` | bool, on | XDG dirs + mime defaults |
| `cfg.home.tools.enable` | bool, on | `home-manager` CLI in user env |
| `cfg.home.direnv.enable` | bool, on | direnv + nix-direnv (nix.nix keeps dev-shell deps GC-safe) |
| `cfg.home.nix-index.enable` | bool, on | nix-index (command-not-found) + comma (`run nix-index` once) |
| `cfg.home.gpg.enable` | bool, on | gpg + gpg-agent with ssh-agent support |
| `cfg.home.ssh.enable` | bool, on | ssh client: agent keys, connection multiplexing |
| `cfg.home.easyeffects.enable` | bool, on | EasyEffects (also needs audio + desktop) |
| `cfg.home.password-store.enable` | bool, on | pass (`pass init <gpg-id>` on first use) |
| `cfg.home.tmux.enable` | bool, **off** | tmux — ssh-serving hosts flip it (server does) |
| `cfg.home.obs.enable` | bool, **off** | OBS Studio screen recording (needs a desktop session) |
| `cfg.home.theming.enable` | bool, **off** | runtime wallpaper theming: matugen extracts a Material-You palette from the running wallpaper into `~/.cache/theming/` (bar, kitty, mako, gtk, rofi, hyprlock), waypaper (`SUPER+SHIFT+W`) is the picker, `wallswitch <image>` the CLI. Generated files are outside HM management. Works on any desktop (GNOME/Hyprland/Plasma) — GNOME manages wallpaper natively, theming recolors GTK/Qt. |
| `cfg.home.theming.wallpapers` | listOf path, `[]` | shipped collection installed to `~/Pictures/Wallpapers/` (store symlinks; picking one copies it) |
| `cfg.home.hyprland.wallpaper` | nullOr path, `null` | install-time default wallpaper — seeds `~/.local/state/theming/current` exactly once (the state copy is authoritative afterwards; deleting it re-seeds). Gates hyprpaper (which always loads the state file); null = hyprpaper off. Hyprland-only. |

## Per-host values

| | desktop | laptop | server | wsl |
|---|---|---|---|---|
| `cfg.user.name` | `cat` | `cat` | `cat` | `cat` |
| `cfg.locale.*` | defaults | defaults | defaults | defaults |
| `cfg.nh.flakeDir` | `/etc/nixos` (TODO real path) | `/etc/nixos` (TODO real path) | `/etc/nixos` (TODO real path) | `/home/cat/nixos` |
| `cfg.home.git.name` | `ThePolishcat` | `ThePolishcat` | `ThePolishcat` | `ThePolishcat` |
| `cfg.home.hyprland.wallpaper` | `./wallpapers/dusk.png` (install-time default) | – | – | – |
| `cfg.home.theming.enable` | ✓ | – | – | – |
| `cfg.home.theming.wallpapers` | `./wallpapers/` (dusk, dawn, moss, ember) | – | – | – |

`cfg.home.git.email` is `88453875+PolskiKocurek@users.noreply.github.com` on all four hosts (the
legacy flake's commit identity).
