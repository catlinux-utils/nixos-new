# Installation Guide

Complete disk preparation, installation, and post-install steps for this flake.

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `scripts/nixos-disk` | Interactive or flag-driven disk partitioning + formatting (LUKS + Btrfs/ext4/xfs) |
| `scripts/nixos-mount` | Mount prepared disk with all subvolumes for `nixos-install` |
| `scripts/nixos-umount` | Safely unmount and close LUKS |
| `scripts/nixos-format-part` | Format selected existing partitions per-partition (FS, encryption, subvolumes) |

---

## Quick Start (Interactive — Full End-to-End)

### Option A: New Disk (partition + format)

```bash
# 1. Boot installer ISO or live Linux (as root)
sudo ./scripts/nixos-disk /dev/nvme0n1
# → prompts for: encryption, filesystems, layout, sizes

# 2. Mount everything
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Generate hardware config INTO THE REPO (tracked, host-specific)
#    Run from repo root (on target or via SSH):
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop

# 4. Commit the hardware config
git add hosts/desktop/hardware-configuration.nix
git commit -m "desktop: add hardware config"

# 5. Install
nixos-install --flake .#desktop --root /mnt

# 6. Reboot into the new system
reboot
```

### Option B: Existing Partitions (format in place)

```bash
# 1. Boot installer ISO or live Linux (as root)
# Format selected partitions interactively:
sudo ./scripts/nixos-format-part -d /dev/nvme0n1 -i
# Or non-interactive:
# sudo ./scripts/nixos-format-part -p ESP=/dev/nvme0n1p1 -p cryptroot=/dev/nvme0n1p2 \
#   -f ESP=vfat -f cryptroot=btrfs -e ESP=no -e cryptroot=yes \
#   -l cryptroot=cryptroot -s cryptroot="@ @home @snapshots @log @nix" -m cryptroot=/mnt -y

# 2. Mount everything
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Generate hardware config INTO THE REPO (tracked, host-specific)
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop

# 4. Commit the hardware config
git add hosts/desktop/hardware-configuration.nix
git commit -m "desktop: add hardware config"

# 5. Install
nixos-install --flake .#desktop --root /mnt

# 6. Reboot into the new system
reboot
```

---

### Post-Install: On the booted target machine, clone repo & rebuild

```bash
# Clone flake to where nh expects it (default /etc/nixos)
git clone https://github.com/ThePolishcat/nixos-new.git /etc/nixos
cd /etc/nixos

# Fix ownership so your user can run nh
chown -R cat:users /etc/nixos

# First rebuild — dry-run, then switch
nh os switch --dry
nh os switch

# (Optional) Home Manager only
nh home switch
```

**Notes:**
- `--no-filesystems` skips the generated `fileSystems` block — this repo manages mounts via `disko.nix` / `scripts/nixos-mount`.
- The `wsl` host doesn't need `hardware-configuration.nix` — NixOS-WSL owns boot and the filesystem.
- Set `cfg.user.initialHashedPassword` in the host config for first login; otherwise the account is locked until you run `passwd` from a root shell.

---

## Non-Interactive (CI / Scripted)

### Desktop: single encrypted root, btrfs, swap partition

```bash
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home no --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --swap-size 8G --boot-size 1G \
  /dev/nvme0n1

sudo ./scripts/nixos-mount /dev/nvme0n1
nixos-install --flake .#desktop --root /mnt
```

### Laptop: separate encrypted /home

```bash
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home yes --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --root-size 50G --home-size 200G \
  /dev/nvme0n1

sudo ./scripts/nixos-mount /dev/nvme0n1
nixos-install --flake .#laptop --root /mnt
```

### Server: root + separate data partition

```bash
sudo ./scripts/nixos-disk --layout server /dev/nvme0n1

sudo ./scripts/nixos-mount /dev/nvme0n1
nixos-install --flake .#server --root /mnt
```

### Existing Partitions (non-interactive format-part)

```bash
sudo ./scripts/nixos-format-part \
  -p ESP=/dev/nvme0n1p1 -p cryptroot=/dev/nvme0n1p2 \
  -f ESP=vfat -f cryptroot=btrfs \
  -e ESP=no -e cryptroot=yes \
  -l cryptroot=cryptroot \
  -s cryptroot="@ @home @snapshots @log @nix" \
  -m cryptroot=/mnt \
  -y

sudo ./scripts/nixos-mount /dev/nvme0n1
nixos-install --flake .#desktop --root /mnt
```

---

## Partition Layouts Created

| Layout | Partitions | Subvolumes |
|--------|------------|------------|
| **auto** (default) | ESP (1G) + cryptroot (rest) [+ cryptswap] | `@`, `@home`, `@snapshots`, `@log`, `@nix` |
| **manual** | You choose sizes | Per your selection |
| **server** | ESP + cryptroot (100G) + cryptdata (rest) | root: `@` `@home` `@snapshots` `@log` `@nix`; data: `docker`, `containers`, `syncthing`, `backups`, `libvirt` |

All LUKS2, labeled (`ESP`, `cryptroot`, `crypthome`, `cryptdata`, `cryptswap`) for auto-detection.

---

## Manual Partition Formatting (Existing Partitions) — Reference

If partitions already exist and you want to format them individually:

### Interactive

```bash
sudo ./scripts/nixos-format-part -d /dev/nvme0n1 -i
```

### Non-interactive

```bash
sudo ./scripts/nixos-format-part \
  -p ESP=/dev/nvme0n1p1 -p cryptroot=/dev/nvme0n1p2 \
  -f ESP=vfat -f cryptroot=btrfs \
  -e ESP=no -e cryptroot=yes \
  -l cryptroot=cryptroot \
  -s cryptroot="@ @home @snapshots @log @nix" \
  -m cryptroot=/mnt \
  -y
```

See `nixos-format-part --help` for all options.

---

## Hardware Configuration — Generate & Pull Into Repo

After mounting the target system at `/mnt`, generate the hardware config **into the repo** so it's tracked and host-specific:

```bash
# From repo root (on the target machine or via SSH):
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop
```

This writes/overwrites `hosts/desktop/hardware-configuration.nix` with the detected hardware (kernel modules, firmware, disks, etc.). The `--no-filesystems` flag skips the generated `fileSystems` block since this repo manages mounts via `disko.nix` / `scripts/nixos-mount`.

**Commit it:**

```bash
git add hosts/desktop/hardware-configuration.nix
git commit -m "desktop: add hardware config"
```

Repeat for each host (`laptop`, `server`). The `wsl` host doesn't need one — NixOS-WSL owns boot and the filesystem.

---

## Post-Install: Copy Repo to Host & First Rebuild

After `nixos-install` completes and you reboot into the new system, the flake isn't on the host yet. Clone it to the location `cfg.nh.flakeDir` expects (default `/etc/nixos`), then run the first rebuild:

```bash
# On the target machine (as root or your user with sudo):

# 1. Clone the repo to /etc/nixos (adjust URL/branch)
git clone https://github.com/ThePolishcat/nixos-new.git /etc/nixos
cd /etc/nixos

# 2. Ensure your user owns it (so nh can write the flake lock, etc.)
chown -R cat:users /etc/nixos

# 3. First rebuild — dry-run to verify, then switch
nh os switch --dry
nh os switch

# 4. (Optional) Home Manager only
nh home switch
```

**If you set `cfg.user.initialHashedPassword` in the host config** (required for first login — see PLAN Phase 2), you can log in as your user immediately. Otherwise the account is locked until you set a password via `passwd` from a root shell.

**WSL host** — different flow: the flake lives in Windows at `cfg.nh.flakeDir` (e.g. `C:\Users\cat\nixos`), and you run `wsl.exe -d NixOS` to enter. See the `wsl` host config for details.

---

## Encryption Notes

- **LUKS2** with AES-NI: ~0% performance overhead on modern CPUs
- **TRIM/DISCARD** passes through: `fstrim.timer` enabled via `cfg.storage.enable`
- **TPM2 auto-unlock**: Configure via `cfg.boot.secureBoot.measuredBoot.autoCryptenroll` (needs Secure Boot + TPM2)
- **Swap**: Encrypted partition or swapfile on Btrfs (hibernation needs `resume=` kernel param)

---

## Filesystem Choice

| FS | Pros | Cons |
|----|------|------|
| **btrfs** | Snapshots, compression (zstd), subvolumes, send/receive | Slightly more complex |
| **ext4** | Simple, universal, fast | No native snapshots/compression |
| **xfs** | Scalable, fast for large files | No shrink, no native snapshots |

Btrfs + zstd recommended for desktop/laptop (compresses game assets, shaders, configs).