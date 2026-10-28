# nixos-new

ThePolishcat's NixOS configuration flake — multiple hosts, Home Manager wired in as a NixOS
module, `nh` for rebuilds, Lix as the Nix implementation, stable nixpkgs (26.05) with unstable
available as `pkgs.unstable.<pkg>`.

> **Status:** scaffold implemented — not yet machine-validated (`nix flake check` / `nix fmt` need
> a Nix machine; see [TODO.md](TODO.md)). The `wsl` host (Phase 1.5) is the planned local
> validation path — its distro bootstrap is pending; the manual CI workflow
> ([.github/workflows/ci.yml](.github/workflows/ci.yml)) is the interim one. [PLAN.md](PLAN.md)
> contains the full spec and roadmap. Agents working in this repo: start with [AGENTS.md](AGENTS.md).

## Hosts

| Host | Role | Session |
|---|---|---|
| `desktop` | workstation | Hyprland |
| `laptop` | portable | GNOME |
| `server` | headless | none (ssh + docker) |
| `wsl` | NixOS-WSL dev host (local validation from Windows, Phase 1.5) | none |

All features are toggleable modules under the `cfg.*` option namespace — hosts flip
switches, modules stay machine-agnostic. The per-host `hardware-configuration.nix` files are
placeholders until `nixos-generate-config` runs on each machine (PLAN Phase 2).

Plus the live installer ISO — `hosts/installer`, a host that builds as an image (no
hardware-configuration; boots into the Hyprland desktop with GDM Wayland autologin): on a Nix
machine, `nixos-rebuild build-image --flake .#installer --image-variant iso`.

## Usage (once scaffolded)

The flake is expected wherever each host's `cfg.nh.flakeDir` points (default `/etc/nixos`):

```bash
nh os switch    # build & activate OS + Home Manager for this host
nh os test      # activate without adding a boot entry
nh home switch  # user environment only
nh clean        # garbage-collect old generations (also runs weekly)
nix fmt         # format the repo (RFC 101 style)
```

## Docs

- [PLAN.md](PLAN.md) — roadmap; Phase 1 is the complete scaffold spec
- [AGENTS.md](AGENTS.md) — conventions, environment constraints, recipes for agents
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the flake fits together (data flow, option
  tree, host assembly)
- [docs/OPTIONS.md](docs/OPTIONS.md) — every `cfg.*` option: type, default, effect, per-host
  matrix
- [TODO.md](TODO.md) — actionable next steps

## Disk Preparation & Installation

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/nixos-disk` | Interactive or flag-driven disk partitioning + formatting (LUKS + Btrfs/ext4/xfs) |
| `scripts/nixos-mount` | Mount prepared disk with all subvolumes for `nixos-install` |
| `scripts/nixos-umount` | Safely unmount and close LUKS |
| `scripts/nixos-prep-disk` | Quick formatter for existing labeled partitions |

### Quick Start (Interactive)

```bash
# 1. Boot installer ISO or live Linux (as root)
sudo ./scripts/nixos-disk /dev/nvme0n1
# → prompts for: encryption, filesystems, layout, sizes

# 2. Mount everything
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Generate hardware config (optional, nixos-anywhere does this)
nixos-generate-config --root /mnt

# 4. Install
nixos-install --flake .#desktop --root /mnt

# 5. Reboot
reboot
```

### Non-Interactive (CI / Scripted)

```bash
# Desktop: single encrypted root, btrfs, swap partition
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home no --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --swap-size 8G --boot-size 1G \
  /dev/nvme0n1

# Laptop: separate encrypted /home
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home yes --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --root-size 50G --home-size 200G \
  /dev/nvme0n1

# Server: root + separate data partition
sudo ./scripts/nixos-disk --layout server /dev/nvme0n1

# Then mount and install
sudo ./scripts/nixos-mount /dev/nvme0n1
nixos-install --flake .#server --root /mnt
```

### Partition Layouts Created

| Layout | Partitions | Subvolumes |
|--------|------------|------------|
| **auto** (default) | ESP (1G) + cryptroot (rest) [+ cryptswap] | `@`, `@home`, `@snapshots`, `@log`, `@nix` |
| **manual** | You choose sizes | Per your selection |
| **server** | ESP + cryptroot (100G) + cryptdata (rest) | root: `@` `@home` `@snapshots` `@log` `@nix`; data: `docker`, `containers`, `syncthing`, `backups`, `libvirt` |

All LUKS2, labeled (`ESP`, `cryptroot`, `crypthome`, `cryptdata`, `cryptswap`) for auto-detection.

### Using with nixos-anywhere

```bash
# From your build machine (with flake + SSH access to target):
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-facter ./hosts/desktop/facter.json \
  --flake .#desktop \
  --target-host root@192.168.1.50

# nixos-anywhere will:
# 1. kexec into installer (or use existing OS)
# 2. Run disko (using your disko.nix)
# 3. Generate hardware config (facter.json)
# 4. Install NixOS
# 5. Reboot
```

### Manual Disk Prep (Existing Partitions)

If partitions already exist with correct labels:

```bash
sudo ./scripts/nixos-prep-disk
# → selects disk, profile (desktop/laptop/server), formats in place
```

### Encryption Notes

- **LUKS2** with AES-NI: ~0% performance overhead on modern CPUs
- **TRIM/DISCARD** passes through: `fstrim.timer` enabled via `cfg.storage.enable`
- **TPM2 auto-unlock**: Configure via `cfg.boot.secureBoot.measuredBoot.autoCryptenroll` (needs Secure Boot + TPM2)
- **Swap**: Encrypted partition or swapfile on Btrfs (hibernation needs `resume=` kernel param)

### Filesystem Choice

| FS | Pros | Cons |
|----|------|------|
| **btrfs** | Snapshots, compression (zstd), subvolumes, send/receive | Slightly more complex |
| **ext4** | Simple, universal, fast | No native snapshots/compression |
| **xfs** | Scalable, fast for large files | No shrink, no native snapshots |

Btrfs + zstd recommended for desktop/laptop (compresses game assets, shaders, configs).
