# Options — the complete `cfg.*` reference

Every knob a host can set, in one place. Options are declared in the NixOS module tree
(`modules/nixos/*.nix`; home-feature options in `modules/nixos/home-options.nix`) and hosts set
them in `hosts/<name>/default.nix` under the flat `cfg.*` tree.

Conventions: feature switches are `lib.mkEnableOption` → **default off**; hosts flip them.
Home-feature options default **on** unless noted (a sane user environment for free). To
re-derive this list: `grep -rn "options.cfg" modules/nixos/`.

## Always on (no switch)

These modules apply on every host — only their value options are configurable:

| Module | Options (type, default) | Effect |
|---|---|---|
| `logging.nix` | — | journald: persistent storage + size cap |
| `nix.nix` | — | Lix, flakes, allowUnfree, store optimisation, pinned registry, no channels, GC-survivor settings for direnv |
| `nh.nix` | `cfg.nh.flakeDir` (path, `/etc/nixos`) | `nh` CLI + weekly GC; flake path via `NH_FLAKE` |
| `locale.nix` | `cfg.locale.timeZone` (str, `Europe/Warsaw`) · `cfg.locale.defaultLocale` (str, `en_US.UTF-8`) · `cfg.locale.keyboard` (str, `pl`) | timezone, locale set, console + X/Wayland keymap |
| `users.nix` | `cfg.user.name` (str, `polishcat`) · `cfg.user.fullName` (str, `ThePolishcat`) · `cfg.user.initialHashedPassword` (nullOr str, `null`) | creates the main user (wheel, zsh login shell); password only for first deploy |

## System feature switches

Default off unless noted. "On" = hosts currently setting it.

| Option | Turns on | desktop | laptop | server | wsl |
|---|---|:---:|:---:|:---:|:---:|
| `cfg.boot.enable` | systemd-boot, EFI vars, silent boot, zram | ✓ | ✓ | ✓ | – (WSL owns boot) |
| `cfg.networking.networkManager.enable` | NetworkManager | ✓ | ✓ | – | – |
| `cfg.networking.firewall.enable` (default **on**) | nftables firewall; ports via sub-options below | ✓ | ✓ | ✓ | ✗ (set false — Windows filters) |
| `cfg.audio.enable` | PipeWire + rtkit | ✓ | ✓ | – | – (WSLg) |
| `cfg.graphics.enable` | OpenGL/VA-API base stack | ✓ | ✓ | – | – |
| `cfg.ssh.enable` | OpenSSH, keys only | ✓ | ✓ | ✓ | – |
| `cfg.virtualisation.docker.enable` | Docker + weekly auto-prune, docker group | – | – | ✓ | – |
| `cfg.virtualisation.libvirt.enable` | libvirtd + virt-manager, libvirtd group | – | – | – | – |
| `cfg.gaming.enable` | Steam + gamescope, GameMode, MangoHud, xpadneo; mkDefaults `graphics.enable32Bit` | ✓ | – | – | – |
| `cfg.sandbox.flatpak.enable` | Flatpak + Flathub bootstrap + Flatseal | – | – | – | – |
| `cfg.sandbox.firejail.enable` | Firejail | – | – | – | – |
| `cfg.compat.nix-ld.enable` | nix-ld loader shim | ✓ | ✓ | ✓ | ✓ |
| `cfg.compat.envfs.enable` | envfs FUSE (`/bin`, `/usr/bin` shebangs) | ✓ | ✓ | – | – |
| `cfg.compat.appimage.enable` | AppImage via binfmt | ✓ | ✓ | – | – |
| `cfg.firmware.enable` | fwupd | ✓ | ✓ | ✓ | – |
| `cfg.storage.enable` | weekly fstrim + smartd | ✓ | ✓ | ✓ | – |
| `cfg.bluetooth.enable` | bluez + blueman applet | ✓ | ✓ | – | – |
| `cfg.printing.enable` | CUPS + Avahi mDNS + SANE (scanner/lp groups) | ✓ | ✓ | – | – |
| `cfg.geolocation.enable` | geoclue2 (night light, auto timezone) | ✓ | ✓ | – | – |
| `cfg.tailscale.enable` | tailscaled (mesh client; `tailscale up` once per host) | ✓ | ✓ | ✓ | – |
| `cfg.syncthing.enable` | syncthing as the main user (Web UI on 127.0.0.1:8384) | ✓ | ✓ | ✓ | – |
| `cfg.secrets.enable` | sops-nix defaults (age via SSH host key, `secrets/secrets.yaml`); needs the master age identity set up first (see `.sops.yaml`) | – | – | – | – |

### Sub-options (set per host when needed)

| Option | Type, default | Purpose |
|---|---|---|
| `cfg.networking.firewall.allowedTCPPorts` / `.allowedUDPPorts` | listOf port, `[]` | per-host firewall openings |
| `cfg.ssh.port` | port, `22` | SSH listen port |
| `cfg.ssh.authorizedKeys` | listOf str, `[]` | keys for the main user — **required on a fresh keys-only host** |
| `cfg.graphics.enable32Bit` | bool (mkEnableOption → off; `gaming` mkDefaults it on) | 32-bit GL for Steam |
| `cfg.compat.nix-ld.libraries` | listOf package, `[]` | libs for non-Nix binaries |
| `cfg.user.initialHashedPassword` | nullOr str, `null` | first-deploy password — locked account without it (see PLAN Phase 2) |

## Desktop session

One DE per host — an assertion makes two enabled DEs fail evaluation. DE modules set
`cfg.desktop.enable` themselves (fonts, portals, dconf, xdg base) and `mkDefault` graphics/audio.

| Option | Turns on | desktop | laptop | server | wsl |
|---|---|:---:|:---:|:---:|:---:|
| `cfg.desktop.gnome.enable` | GNOME (GDM) | – | ✓ | – | – |
| `cfg.desktop.hyprland.enable` | Hyprland via uwsm (+ PAM hyprlock) | ✓ | – | – | – |
| `cfg.desktop.plasma.enable` | KDE Plasma 6 (SDDM) | – | – | – | – |

## Home options (`cfg.home.*`)

Declared in `modules/nixos/home-options.nix`; the option-less modules in `modules/home/` gate on
them via `osConfig`. All default **true** except where noted. Modules with **no option** ride
system switches instead: `browser.nix`, `vscode.nix`, `mpv.nix` and `easyeffects.nix` also
require `cfg.desktop.enable` (easyeffects also `cfg.audio.enable`), `gnome.nix` gates on
`cfg.desktop.gnome.enable`, and the `hyprland/` folder on `cfg.desktop.hyprland.enable`.

| Option | Type, default | Effect |
|---|---|---|
| `cfg.home.shell.enable` | bool, on | zsh + starship + fzf/eza/btop/bat/zoxide/atuin/yazi/lazygit/tealdeer |
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
| `cfg.home.hyprland.wallpaper` | nullOr path, `null` | hyprpaper image; null = hyprpaper off |

## Per-host values

| | desktop | laptop | server | wsl |
|---|---|---|---|---|
| `cfg.user.name` | `polishcat` | `polishcat` | `polishcat` | `polishcat` |
| `cfg.locale.*` | defaults | defaults | defaults | defaults |
| `cfg.nh.flakeDir` | `/etc/nixos` (TODO real path) | `/etc/nixos` (TODO real path) | `/etc/nixos` (TODO real path) | `/home/polishcat/nixos-new` |
| `cfg.home.git.name` | `ThePolishcat` | `ThePolishcat` | unset | `ThePolishcat` |
| `cfg.home.git.email` | TODO | TODO | — | TODO |
