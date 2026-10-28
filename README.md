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
