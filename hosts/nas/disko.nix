{
  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "mode=755"
      ];
    };
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.002538b581b34925";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "8G";
              content.type = "swap";
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "rootfs";
                label = "nvme.nvme0n1";
                extraFormatArgs = [
                  "--discard"
                  "--durability=0"
                ];
              };
            };
          };
        };
      };
      sda = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2527E9C5CD54";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot1";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "rootfs";
                label = "sata.sda";
                extraFormatArgs = [
                  "--discard"
                  "--durability=1"
                ];
              };
            };
          };
        };
      };
      sdb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4CZNF1N102994T";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot2";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "rootfs";
                label = "sata.sdb";
                extraFormatArgs = [
                  "--discard"
                  "--durability=1"
                ];
              };
            };
          };
        };
      };
    };
    bcachefs_filesystems.rootfs = {
      type = "bcachefs_filesystem";
      extraFormatArgs = [
        "--replicas=2"
        "--compression=lz4"
      ];
      subvolumes = {
        nix.mountpoint = "/nix";
        persist.mountpoint = "/persist";
      };
    };
  };
}
