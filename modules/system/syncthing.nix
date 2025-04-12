{ config, lib, ... }:
let
  cfg = config.myConfig.syncthing;
in
{
  options.myConfig.syncthing = {
    enable = lib.mkEnableOption "";
    isServer = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      user = lib.mkIf (!cfg.isServer) "seb";
      group = lib.mkIf (!cfg.isServer) "users";
      dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

      guiAddress = lib.mkIf cfg.isServer "0.0.0.0:8384";

      settings = {
        devices = {
          alto = {
            id = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
            addresses = [ "tcp://alto.${config.networking.domain}:22000" ];
          };
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
                path = "${config.services.syncthing.dataDir}/${name}";
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
