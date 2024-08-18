{
  disko.devices = {
    disk =
      let
        luks-settings = {
          settings = {
            allowDiscards = true;
            keyFile = "/dev/disk/by-id/usb-SCSI_DISK-0:0";
            keyFileSize = 4096;
          };
        };
      in
      {
        one = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "512M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "defaults" ];
                };
              };
              luks = {
                size = "100%";
                content = {
                  name = "cryptroot";
                  type = "luks";
                  content = {
                    type = "lvm_pv";
                    vg = "root-pool";
                  };
                } // luks-settings;
              };
            };
          };
        };
        two = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions.luks = {
              size = "100%";
              content = {
                name = "cryptdata";
                type = "luks";
                content = {
                  type = "lvm_pv";
                  vg = "data-pool";
                };
              } // luks-settings;
            };
          };
        };
      };

    lvm_vg = {
      root-pool = {
        type = "lvm_vg";
        lvs.root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "defaults" ];
          };
        };
      };
      data-pool = {
        type = "lvm_vg";
        lvs.data = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/data";
            mountOptions = [ "defaults" ];
          };
        };
      };
    };
  };
}
