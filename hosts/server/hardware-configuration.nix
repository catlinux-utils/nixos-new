# PLACEHOLDER — replace with real `nixos-generate-config` output on this machine (Phase 2).
# Mounts come from disko.nix; until the machine is installed, only the
# stateVersion marker lives here.
{ ... }:
{
  # first-install marker — real nixos-generate-config output sets it too; keep the original value
  system.stateVersion = "26.05";
}
