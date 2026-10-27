---
name: add-host
description: Register a new machine as a host in this flake (hosts/<name>/ directory + flake.nix entry). Use whenever the user says "add a host" / "add a machine", mentions bringing a new NixOS install under this flake, or works on the Phase 1.5 WSL host or Phase 2 hardware bring-up for a specific machine.
---

# Add a host

A host is one directory plus one flake line — `lib/mkHost.nix` does the assembly.

## Steps

1. **`hosts/<name>/default.nix`** — the self-contained host entry: one `cfg = { ... }` tree,
   sectioned in this order: identity (`user`), locale, `nh.flakeDir`, git identity
   (`home.git`), then feature switches. No implementation logic. Copy the shape from
   `hosts/desktop/default.nix`.

2. **`hosts/<name>/hardware-configuration.nix`** — real output of `nixos-generate-config` run
   on that machine. **Never hand-write disk config.** If the machine isn't reachable yet, use
   the minimal-but-valid placeholder skeleton from PLAN.md §1.7 with its `# PLACEHOLDER`
   comment, and leave a TODO.md item to replace it.

3. **Register in `flake.nix`:**

   ```nix
   nixosConfigurations.<name> = mkHost { hostname = "<name>"; };
   ```

4. **Foreign-arch binaries** (e.g. aarch64 emulation on x86): set `boot.binfmt.emulatedSystems`
   directly in the host file — a per-host decision, deliberately not a toggle.

5. **Non-standard platforms** (e.g. the Phase 1.5 NixOS-WSL host): follow that phase's notes in
   PLAN.md — import the platform module as an extra input/module, skip boot loader config, and
   leave the irrelevant toggles (audio, graphics, NetworkManager) off.

6. **First-deploy safety (locked-account rule):** before the first `nh os switch` on a fresh
   machine, the host file must set `cfg.user.initialHashedPassword` (or enroll the admin key
   into root's `openssh.authorizedKeys`). With no password the account is locked: key-SSH
   works, but `sudo`, console and GDM login all fail — nothing fixable remotely. Flag this to
   the user if it's missing from a new host file.

## Doc sync

- README.md: add the host to the host table.
- PLAN.md: update the status/host matrix if the phase notes track it.
- docs/ARCHITECTURE.md: only if the assembly scheme itself changed (a plain host addition
  doesn't).

## Validation

On the machine (or any Nix box): `nix flake check` → `nh os switch --dry` → `nh os test` →
`nh os switch`. Never claim these ran unless they actually did — see the `nix-validate` skill.
