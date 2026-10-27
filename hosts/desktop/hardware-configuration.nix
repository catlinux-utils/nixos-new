# PLACEHOLDER — replace with real `nixos-generate-config` output on this machine (Phase 2).
{ ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # first-install marker — real nixos-generate-config output sets it too; keep the original value
  system.stateVersion = "26.05";
}
