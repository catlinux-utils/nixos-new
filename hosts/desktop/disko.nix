# Desktop disk layout: Btrfs on LUKS (no separate /home encryption needed —
# single LUKS container, subvolumes provide isolation). Adjust `device` to the
# target disk (e.g. /dev/nvme0n1, /dev/sda) before using with nixos-anywhere
# or the installer.
{
  lib,
  config,
  ...
}: {
  imports = [ ./hardware-configuration.nix ];

  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/REPLACE_WITH_DISK_ID"; # e.g. nvme-Samsung_SSD_970_EVO_...
        type = "gpt";
        wipeFreespace = true;
        partitions = {
          esp = {
            size = "1G";
            type = "EF00"; # EFI System Partition
            format = {
              type = "vfat";
              label = "ESP";
            };
            mountpoint = "/boot";
          };
          cryptroot = {
            size = "100%"; # rest of disk
            type = "8309"; # Linux LUKS
            encryption = {
              type = "luks2";
              label = "cryptroot";
              # keyFile = "/etc/keys/root.key"; # optional: TPM2-backed key (Phase 2 TPM2-LUKS)
            };
            # Btrfs on LUKS — subvolumes created by disko + systemd-tmpfiles
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