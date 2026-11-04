# nixos-new

ThePolishcat's NixOS configuration flake. A single flake manages several machines
(`desktop`, `laptop`, `server`, `wsl`) plus a live installer ISO. Home Manager is
wired in as a NixOS module, rebuilds go through `nh`, and the Nix implementation is
Lix on nixpkgs **26.05**, with unstable available as `pkgs.unstable.<pkg>`.

All features are toggleable modules under the `cfg.*` option namespace: hosts flip
switches in `hosts/<name>/default.nix`, modules stay machine-agnostic.

## Hosts

| Host | Role | Session |
|------|------|---------|
| `desktop` | workstation | Hyprland |
| `laptop` | portable | GNOME |
| `server` | headless | none (SSH + Docker) |
| `wsl` | NixOS-WSL dev host | none |
| `installer` | live ISO — boots into the repo's Hyprland desktop via greetd autologin | Hyprland |

The installer is a regular host that builds as an image (it has no
`hardware-configuration.nix`; the `iso` image variant owns the bootloader):

```bash
nixos-rebuild build-image --flake .#installer --image-variant iso
```

The ISO embeds the **committed** repo tree (available in the live session at
`~/github/nixos`) — commit before building or the image ships a stale tree.

## Usage

The flake lives wherever the host's `cfg.nh.flakeDir` points — `~/github/nixos` on all
real hosts (`/etc/nixos` is only the option's fallback default):

```bash
nh os switch    # build & activate OS + Home Manager for this host
nh os test      # activate without adding a boot entry
nh home switch  # user environment only
nh clean        # garbage-collect old generations (also runs weekly)
nix fmt         # format the repo (RFC 101 style)
```

## Installation

The full guide — disk preparation, hardware-config generation, non-interactive
variants — is [docs/INSTALL.md](docs/INSTALL.md). Abridged, from a live environment:

```bash
# 0. Clone this repo
git clone https://github.com/ThePolishcat/nixos-new.git
cd nixos-new

# 1. Partition & format the target drive — interactive prompts, incl. the
#    disk picker (reusing existing partitions instead? sudo ./scripts/nixos-format-part -i)
sudo ./scripts/nixos-disk

# 2. Mount — auto-detects the disk carrying cryptroot
sudo ./scripts/nixos-mount

# 3. Generate the hardware config into the repo
#    (sudo: the btrfs probe needs root; the redirect in your own shell keeps
#    the file owned by the live-session user)
sudo nixos-generate-config --show-hardware-config --no-filesystems \
  > hosts/desktop/hardware-configuration.nix

# 4. Install (sudo: nixos-install lays down the target's system closure)
sudo nixos-install --flake .#desktop --root /mnt

# 5. Copy the repo onto the new system (reads the target user from the host file)
sudo ./scripts/nixos-copy-repo desktop

# 6. Reboot, then run `nh os switch` from ~/github/nixos
reboot
```

Notes:

- The installer ISO ships this repo in the live session at `~/github/nixos`
  (home of the passwordless `nixos` user) — install straight from there with
  `nixos-install --flake ~/github/nixos#<host>`, no clone needed. The copy is
  git-cleaned (no `.git`); re-clone or pull for editing history.
- The `cat` user ships with initial password `cat` (`cfg.user.initialHashedPassword`
  in the host config) — change it on first login.
- Helper scripts: `nixos-disk`, `nixos-mount` (mount / `--umount`), `nixos-format-part`,
  `nixos-copy-repo` (repo onto the target pre-reboot) —
  documented in [docs/INSTALL.md](docs/INSTALL.md).

## Documentation

- [docs/INSTALL.md](docs/INSTALL.md) — complete installation guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the flake fits together
- [docs/OPTIONS.md](docs/OPTIONS.md) — the `cfg.*` option reference
