{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "16G";
            content = {
              type = "swap";
              discardPolicy = "both";
            };
          };
          nix = {
            size = "60G";
            content = {
              type = "filesystem";
              format = "xfs";
              extraArgs = [
                "-m"
                "reflink=1"
              ];
              mountpoint = "/nix";
              mountOptions = [ "noatime" ];
            };
          };
          persist = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "mode=755"
      ];
    };
  };
}
