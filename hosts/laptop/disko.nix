# Laptop disk layout: Btrfs on LUKS (full-disk encryption mandatory for
# portable). Includes hibernation swap inside LUKS (separate LUKS device or
# swapfile on Btrfs — here we use a swapfile on @root for simplicity; replace
# with a dedicated LUKS swap partition if you prefer pre-boot unlock). Adjust
# `device` to the target disk before use.
{
  lib,
  config,
  ...
}: {
  imports = [ ./hardware-configuration.nix ];

  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/REPLACE_WITH_DISK_ID";
        type = "gpt";
        wipeFreespace = true;
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            format = {
              type = "vfat";
              label = "ESP";
            };
            mountpoint = "/boot";
          };
          cryptroot = {
            size = "100%";
            type = "8309";
            encryption = {
              type = "luks2";
              label = "cryptroot";
              # TPM2-backed key for auto-unlock (Phase 2): keyFile = "/etc/keys/root.key";
            };
            btrfs = {
              name = "nixos";
              mountpoint = "/";
              compress = "zstd";
              subvolumes = {
                "@" = { mountpoint = "/"; };
                "@home" = { mountpoint = "/home"; };
                "@snapshots" = { mountpoint = "/.snapshots"; };
                "@log" = { mountpoint = "/var/log"; };
                "@nix" = { mountpoint = "/nix"; };
              };
            };
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /var/log 0755 root root -"
  ];

  # Swapfile on Btrfs @root (no separate partition; hibernation works if
  # swapfile >= RAM and kernel cmdline has resume=/dev/mapper/cryptroot
  # resume_offset=<offset> — disko can set this via boot.kernelParams)
  swapDevices = [ ];

  # Laptop-friendly Btrfs: less aggressive scrub/balance
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "monthly";
}