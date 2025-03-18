{ config, lib, ... }:
{
  options.myConfig.syncthing.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.syncthing.enable {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22000 ];

    services.syncthing = {
      enable = true;

      user = "seb";
      group = "users";
      dataDir = "/home/seb";

      settings = {
        devices = {
          fern = {
            id = "Q4YPD3V-GXZPHSN-PT5X4PU-FBG4GX2-IASBX75-7NYMG75-4EJHBMZ-4WGDDAP";
            addresses = [ "tcp://fern.${config.networking.domain}:22000" ];
          };
          north = {
            id = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";
            addresses = [ "tcp://north.${config.networking.domain}:22000" ];
          };
        };

        folders =
          let
            genFolders =
              folders:
              lib.genAttrs folders (name: {
                path = "~/${name}";
                ignorePerms = false;
                devices = lib.attrNames config.services.syncthing.settings.devices;
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

        options = {
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
          autoUpgradeIntervalH = 0;
        };
      };
    };
  };
}
