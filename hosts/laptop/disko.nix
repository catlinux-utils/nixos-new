# Laptop disk layout: Btrfs on LUKS (full-disk encryption mandatory for
# portable). Includes hibernation swap inside LUKS (separate LUKS device or
# swapfile on Btrfs — here we use a swapfile on @ for simplicity; replace
# with a dedicated LUKS swap partition if you prefer pre-boot unlock). Adjust
# `device` to the target disk before use.
{ ... }:
{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/REPLACE_WITH_DISK_ID";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "1G";
          type = "EF00"; # EFI System Partition
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        cryptroot = {
          size = "100%"; # rest of disk
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            # TPM2-backed key for auto-unlock (Phase 2): keyFile = "/etc/keys/root.key";
            # Btrfs on LUKS — subvolumes created by disko at format time
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/@" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" ];
                };
                "/@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" ];
                };
                "/@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd" ];
                };
                "/@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "compress=zstd" ];
                };
                "/@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
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

  # Swapfile on Btrfs @ (no separate partition; hibernation works if
  # swapfile >= RAM and kernel cmdline has resume=/dev/mapper/cryptroot
  # resume_offset=<offset> — configure when swap actually lands)
  swapDevices = [ ];

  # Laptop-friendly Btrfs: less aggressive scrub, no balance timer
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "monthly";
}
