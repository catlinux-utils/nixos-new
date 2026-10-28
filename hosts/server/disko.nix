# Server disk layout: Btrfs on LUKS + separate encrypted data partition for
# services (docker, syncthing, backups) — keeps root small and snapshotable,
# data survives root reinstalls. Adjust `device` and sizes.
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
            format = { type = "vfat"; label = "ESP"; };
            mountpoint = "/boot";
          };
          cryptroot = {
            size = "100G"; # root: 100G is plenty for OS + /nix
            type = "8309";
            encryption = { type = "luks2"; label = "cryptroot"; };
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
                # Docker data lives on separate data partition below (not here)
              };
            };
          };
          cryptdata = {
            size = "100%"; # rest of disk for services data
            type = "8309";
            encryption = { type = "luks2"; label = "cryptdata"; };
            btrfs = {
              name = "data";
              mountpoint = "/var/lib";
              compress = "zstd";
              subvolumes = {
                "docker" = { mountpoint = "/var/lib/docker"; };
                "containers" = { mountpoint = "/var/lib/containers"; }; # podman
                "syncthing" = { mountpoint = "/var/syncthing"; };
                "backups" = { mountpoint = "/var/backups"; };
                "libvirt" = { mountpoint = "/var/lib/libvirt"; };
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