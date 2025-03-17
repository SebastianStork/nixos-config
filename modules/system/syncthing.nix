{ config, lib, ... }:
{
  options.myConfig.syncthing.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.syncthing.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;

      user = "seb";
      group = "users";
      dataDir = "/home/seb";

      settings = {
        devices = {
          north.id = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";
        };

        folders =
          let
            genFolders =
              folders:
              lib.genAttrs folders (name: {
                path = "~/${name}";
                ignorePerms = false;
                devices = [
                  "north"
                ];
              });
          in
          genFolders [
            "Documents"
            "Downloads"
            "Music"
            "Pictures"
            "Projects"
            "Videos"
          ];
      };
    };
  };
}
