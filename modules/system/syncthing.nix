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
          north.id = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";
        };

        folders =
          let
            allDevices = [
              "north"
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
