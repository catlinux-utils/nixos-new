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
| `installer` | live ISO — boots into the repo's Hyprland desktop via GDM autologin | Hyprland |

The installer is a regular host that builds as an image (it has no
`hardware-configuration.nix`; the `iso` image variant owns the bootloader):

```bash
nixos-rebuild build-image --flake .#installer --image-variant iso
```

## Usage

The flake lives wherever the host's `cfg.nh.flakeDir` points (default `/etc/nixos`):

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

# 1. Partition & format the target drive (interactive)
sudo ./scripts/nixos-disk /dev/nvme0n1
#    Reusing existing partitions instead? Format in place:
#    sudo ./scripts/nixos-format-part -d /dev/nvme0n1 -i

# 2. Mount
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Ensure /efi/EFI exists (case-sensitive ESP mount fix)
mkdir -p /mnt/efi/EFI

# 4. Generate the hardware config into the repo
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop

# 5. Install
nixos-install --flake .#desktop --root /mnt

# 6. Copy the cloned repo onto the new system (before reboot)
mkdir -p /mnt/home/cat/github
cp -r . /mnt/home/cat/github/nixos
chown -R 1000:100 /mnt/home/cat/github/nixos   # numeric IDs: target isn't booted yet

# 7. Reboot, then run `nh os switch` from ~/github/nixos
reboot
```

Notes:

- The installer ISO ships this repo pre-cloned at `/etc/nixos` — `cd /etc/nixos`
  and skip step 0.
- The `cat` user ships with initial password `cat` (`cfg.user.initialHashedPassword`
  in the host config) — change it on first login.
- Helper scripts: `nixos-disk`, `nixos-mount`, `nixos-umount`, `nixos-format-part` —
  documented in [docs/INSTALL.md](docs/INSTALL.md).

## Documentation

- [docs/INSTALL.md](docs/INSTALL.md) — complete installation guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the flake fits together
- [docs/OPTIONS.md](docs/OPTIONS.md) — the `cfg.*` option reference
