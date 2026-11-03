# Server disk layout: Btrfs on LUKS + separate encrypted data partition for
# services (docker, syncthing, backups) — keeps root small and snapshotable,
# data survives root reinstalls. Adjust `device` and sizes.
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
          size = "100G"; # root: 100G is plenty for OS + /nix
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
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
                # Docker data lives on the separate data partition below
              };
            };
          };
        };
        cryptdata = {
          size = "100%"; # rest of disk for services data
          content = {
            type = "luks";
            name = "cryptdata";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/docker" = {
                  mountpoint = "/var/lib/docker";
                  mountOptions = [ "compress=zstd" ];
                };
                "/containers" = {
                  mountpoint = "/var/lib/containers";
                  mountOptions = [ "compress=zstd" ];
                };
                "/syncthing" = {
                  mountpoint = "/var/syncthing";
                  mountOptions = [ "compress=zstd" ];
                };
                "/backups" = {
                  mountpoint = "/var/backups";
                  mountOptions = [ "compress=zstd" ];
                };
                "/libvirt" = {
                  mountpoint = "/var/lib/libvirt";
                  mountOptions = [ "compress=zstd" ];
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

  # Server: weekly scrub, monthly balance
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
