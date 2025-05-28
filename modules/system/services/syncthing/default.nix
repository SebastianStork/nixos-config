{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.syncthing;
  tsCfg = config.custom.services.tailscale;
in
{
  options.custom.services.syncthing = {
    enable = lib.mkEnableOption "";
    isServer = lib.mkEnableOption "";
    deviceId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = tsCfg.enable;
        message = "syncthing requires tailscale";
      }
    ];

    services.syncthing = {
      enable = true;

      user = lib.mkIf (!cfg.isServer) "seb";
      group = lib.mkIf (!cfg.isServer) "users";
      dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

      guiAddress = lib.mkIf cfg.isServer "0.0.0.0:8384";

      settings = {
        # Get the devices and their ids from the configs of the other hosts
        devices =
          self.nixosConfigurations
          |> lib.filterAttrs (name: _: name != config.networking.hostName)
          |> lib.filterAttrs (_: value: value.config.custom.services.syncthing.enable)
          |> lib.mapAttrs (
            name: value: {
              id = value.config.custom.services.syncthing.deviceId;
              addresses = [ "tcp://${name}.${tsCfg.domain}:22000" ];
            }
          );

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
