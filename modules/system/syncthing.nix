{ config, lib, ... }:
{
  options.myConfig.syncthing.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.syncthing.enable {
    services.syncthing = {
      enable = true;

      user = "seb";
      group = "users";
      dataDir = "/home/seb";

      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = {
          north.id = "ROS2S76-ULQWVFC-7KNQQ6Q-MNIWNKT-2QOPPHY-FFQZNVM-GUJRTHE-NZBM3QY";
          inspiron.id = "K7V6PJV-3HLR6FI-VTFRJRN-ECG2ZYI-TNT4F5G-2WVQBDW-S77CHYL-VCAATAV";
        };

        folders =
          let
            allDevices = [
              "north"
              "inspiron"
            ];
            staggeredVersioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600"; # 1 hour in seconds
                maxAge = "15552000"; # 180 days in seconds
              };
            };
          in
          {
            Documents = {
              path = "/home/seb/Documents";
              devices = allDevices;
              versioning = staggeredVersioning;
              ignorePerms = false;
            };
            Downloads = {
              path = "/home/seb/Downloads";
              devices = allDevices;
              versioning = staggeredVersioning;
              ignorePerms = false;
            };
            Pictures = {
              path = "/home/seb/Pictures";
              devices = allDevices;
              versioning = staggeredVersioning;
              ignorePerms = false;
            };
            Music = {
              path = "/home/seb/Music";
              devices = allDevices;
              versioning = staggeredVersioning;
              ignorePerms = false;
            };
            Videos = {
              path = "/home/seb/Videos";
              devices = allDevices;
              versioning = staggeredVersioning;
              ignorePerms = false;
            };
            Projects = {
              path = "/home/seb/Projects";
              devices = allDevices;
              ignorePerms = false;
            };
          };
      };
    };
  };
}
