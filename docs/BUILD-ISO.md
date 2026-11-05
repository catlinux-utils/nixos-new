# Building the Installer ISO

How to build the live installer ISO (`hosts/installer`) — on NixOS, and on any
other Linux distro with Nix installed.

The ISO is a full mkHost host built as an image: `nixosConfigurations.installer`
plus the `iso` image variant (`image.modules.iso` → `config.system.build.images.iso`).
It boots via UEFI only (no BIOS/GRUB entry), autologins the passwordless `nixos`
user into the repo's Hyprland desktop, and ships this repo at `~/github/nixos`
for offline `nixos-install --flake ~/github/nixos#<host>`.

## Prerequisites (any build machine)

- Linux, with Nix (flakes enabled: `nix-command` + `flakes` experimental features)
- ~15 GB free in `/nix/store` for the closure, plus the ISO size itself (~4 GB)
- Git — see the warning below

**Commit before building.** The ISO embeds the flake's source tree (`self` in
`hosts/installer/default.nix`), copied into the live session at `~/github/nixos`.
Untracked files are invisible to the flake, and a stale tree means the live
environment installs from old host configs. Work from a clean, committed tree.

## On NixOS

```bash
cd ~/github/nixos

# build (the artifact lands in ./result/iso/ via the `result` symlink)
nixos-rebuild build-image --flake .#installer --image-variant iso

# without --image-variant, the command lists the host's available variants
```

Equivalent low-level form — what `build-image` runs under the hood, and what CI
evaluates (`nix flake check` never builds the ISO, it only instantiates this
derivation):

```bash
nix build .#nixosConfigurations.installer.config.system.build.images.iso
```

## On other distros

Two routes; both just need Nix on a Linux host — the build is a plain
derivation, no NixOS required.

### Option 1: native Nix install

```bash
# multi-user (daemon) install — preferred: hardened distros (e.g. recent
# Ubuntu) restrict the unprivileged user namespaces single-user builds rely on
sh <(curl -L https://nixos.org/nix/install) --daemon
```

The official installer does not enable flakes by default. Pass them as a flag
instead of editing config — every `nix` invocation takes
`--experimental-features`, which also has to prefix the `nix run` call itself
(it fetches nixpkgs before `nixos-rebuild` ever starts):

```bash
nix --experimental-features "nix-command flakes" run \
  nixpkgs#nixos-rebuild -- build-image --flake .#installer --image-variant iso
```

Or enable them permanently (edit + daemon restart, no per-command flag):

```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
nix run nixpkgs#nixos-rebuild -- build-image --flake .#installer --image-variant iso
```

SELinux-distros (Fedora) need the extra steps from the Nix manual before the
daemon works.

### Option 2: container (Docker / Podman)

Nothing touches the host system — good for trying a build without installing Nix:

```bash
docker run -it --rm -v "$PWD":/repo -w /repo nixos/nix

# inside the container:
nix --experimental-features "nix-command flakes" run \
  nixpkgs#nixos-rebuild -- build-image --flake .#installer --image-variant iso
```

Rootless Podman works the same way (`podman run …`). The `result` symlink lands
in the mounted directory, so the ISO survives container exit.

## Writing to USB

```bash
lsblk -dno NAME,SIZE,MODEL,TRAN   # find the USB device (whole disk, no partition)
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M oflag=sync status=progress
```

Boot the target machine in UEFI mode — the ISO has no BIOS/CSM boot entry
(`makeBiosBootable = false` in the `iso` variant drops grub from the closure).

## Notes

- **Foreign architectures**: building e.g. an aarch64 ISO from an x86-64 host
  needs binary emulation. On NixOS set `boot.binfmt.emulatedSystems` in the
  *build* machine's config; on other distros set up qemu-user binfmt yourself.
- **Faster/smaller builds**: the `iso` variant in `hosts/installer/default.nix`
  exposes optional toggles — `compressImage` (whole-ISO zstd → `.iso.zst`) and
  `includeSystemBuildDependencies` (offline builds in the live env, at a large
  size cost).
- The embedded repo copy is git-cleaned (no `.git`): installing from the live
  session works, but commit any in-session edits to `hardware-configuration.nix`
  later from the booted host (see [INSTALL.md](INSTALL.md)).
- ISO internals worth knowing when tweaking `hosts/installer/default.nix`:
  volumeID `nixos-nixos-new` (≤32 chars — stage 1 mounts the CD by it), squashfs
  compressed with `zstd -Xcompression-level 6` (upstream default 19 — bigger
  ISO, faster boot on slow machines).
