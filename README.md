# nixos-new

ThePolishcat's NixOS configuration flake — multiple hosts, Home Manager wired in as a NixOS
module, `nh` for rebuilds, Lix as the Nix implementation, stable nixpkgs (25.05) with unstable
available as `pkgs.unstable.<pkg>`.

> **Status:** scaffold specified, not yet built. [PLAN.md](PLAN.md) contains the full executable
> spec (Phase 1). Agents working in this repo: start with [AGENTS.md](AGENTS.md).

## Planned hosts

| Host | Role | Session |
|---|---|---|
| `desktop` | workstation | Hyprland |
| `laptop` | portable | GNOME |
| `server` | headless | none (ssh + docker) |

All features are toggleable modules under the `cfg.*` option namespace — hosts flip
switches, modules stay machine-agnostic.

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
- [TODO.md](TODO.md) — actionable next steps
