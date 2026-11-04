# Desktop disk layout: Btrfs on LUKS (no separate /home encryption needed —
# single LUKS container, subvolumes provide isolation). Adjust `device` to the
# target disk (e.g. /dev/nvme0n1, /dev/sda) before using with nixos-anywhere
# or the installer.
{ ... }:
{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/REPLACE_WITH_DISK_ID"; # e.g. nvme-Samsung_SSD_970_EVO_...
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
            mountpoint = "/efi";
            mountOptions = [ "umask=0077" ];
          };
        };
        cryptroot = {
          size = "100%"; # rest of disk
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            # keyFile = "/etc/keys/root.key"; # optional: TPM2-backed key (Phase 2 TPM2-LUKS)
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

  # Ensure the subvolumes exist at activation (disko creates them at format time;
  # this is a safety net for subsequent rebuilds)
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /var/log 0755 root root -"
  ];

  # Btrfs maintenance — scrub weekly, balance monthly (cheap on desktop SSDs)
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";
  systemd.timers.btrfs-balance = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "monthly";
    timerConfig.Persistent = true;
  };
  systemd.services.btrfs-balance = {
    wantedBy = [ "btrfs-balance.timer" ];
    serviceConfig.Type = "oneshot";
    script = "btrfs balance start -dusage=50 /";
  };
}
