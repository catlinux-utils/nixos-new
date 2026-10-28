# nixos-new

ThePolishcat's NixOS configuration flake — multiple hosts, Home Manager wired in as a NixOS module, `nh` for rebuilds, Lix as the Nix implementation, stable nixpkgs (26.05) with unstable available as `pkgs.unstable.<pkg>`.

> **Status:** scaffold implemented — not yet machine-validated (`nix flake check` / `nix fmt` need a Nix machine; see [TODO.md](TODO.md)). The `wsl` host (Phase 1.5) is the planned local validation path — its distro bootstrap is pending; the manual CI workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) is the interim one. [PLAN.md](PLAN.md) contains the full spec and roadmap. Agents working in this repo: start with [AGENTS.md](AGENTS.md).

## Hosts

| Host | Role | Session |
|---|---|---|
| `desktop` | workstation | Hyprland |
| `laptop` | portable | GNOME |
| `server` | headless | none (ssh + docker) |
| `wsl` | NixOS-WSL dev host (local validation from Windows, Phase 1.5) | none |

Plus the live installer ISO — `hosts/installer`, a host that builds as an image (no hardware-configuration; boots into the Hyprland desktop with GDM Wayland autologin): on a Nix machine, `nixos-rebuild build-image --flake .#installer --image-variant iso`.

All features are toggleable modules under the `cfg.*` option namespace — hosts flip switches, modules stay machine-agnostic.

## Usage

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
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the flake fits together (data flow, option tree, host assembly)
- [docs/OPTIONS.md](docs/OPTIONS.md) — every `cfg.*` option: type, default, effect, per-host matrix
- [docs/INSTALL.md](docs/INSTALL.md) — complete disk preparation, installation, and post-install guide
- [TODO.md](TODO.md) — actionable next steps

## Installation (Quick Reference)

See **[docs/INSTALL.md](docs/INSTALL.md)** for the full guide. The short version:

### New disk (partition + format)
```bash
# 1. Partition & format (interactive or flags)
sudo ./scripts/nixos-disk /dev/nvme0n1

# 2. Mount
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Ensure /efi/EFI exists (case-sensitive ESP mount fix)
mkdir -p /mnt/efi/EFI

# 4. Generate hardware config into repo (commit manually later)
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop

# 5. Install
nixos-install --flake .#desktop --root /mnt

# 6. Copy flake from installer to installed system (before reboot)
mkdir -p /mnt/home/cat/github
cp -r /etc/nixos /mnt/home/cat/github/nixos
chown -R 1000:100 /mnt/home/cat/github/nixos

# 7. Reboot
reboot
```

### Existing partitions (format in place)
```bash
# 1. Format partitions (interactive or flags)
sudo ./scripts/nixos-format-part -d /dev/nvme0n1 -i

# 2. Mount
sudo ./scripts/nixos-mount /dev/nvme0n1

# 3. Ensure /efi/EFI exists (case-sensitive ESP mount fix)
mkdir -p /mnt/efi/EFI

# 4. Generate hardware config into repo (commit manually later)
nixos-generate-config --root /mnt --no-filesystems --dir ./hosts/desktop

# 5. Install
nixos-install --flake .#desktop --root /mnt

# 6. Copy flake from installer to installed system (before reboot)
mkdir -p /mnt/home/cat/github
cp -r /etc/nixos /mnt/home/cat/github/nixos
chown -R 1000:100 /mnt/home/cat/github/nixos

# 7. Reboot
reboot
```

> **Note:** The installer ISO has the flake at `/etc/nixos` (from the build). Copy it to the user's home on the target system. After reboot, run `nh os switch` from `~/github/nixos`. The user `cat` has password `cat` (set via `cfg.user.initialHashedPassword = "cat"` in host config — replace with hashed for production).

Scripts available: `nixos-disk`, `nixos-mount`, `nixos-umount`, `nixos-format-part` — see [docs/INSTALL.md](docs/INSTALL.md) for details.