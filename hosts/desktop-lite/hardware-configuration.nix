# PLACEHOLDER — replace with real `nixos-generate-config` output on this machine (Phase 2).
# Until the machine is installed, only the stateVersion marker and a
# root-fs stub live here.
{ ... }:
{
  # first-install marker — real nixos-generate-config output sets it too; keep the original value
  system.stateVersion = "26.05";

  # placeholder-only stub: keeps stage-1's root-fs assertion happy until the
  # real nixos-generate-config output (run at install time) replaces this file
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot"; # the scripts' LUKS layout name
    fsType = "btrfs";
    options = [ "subvol=/@" ];
  };
}
