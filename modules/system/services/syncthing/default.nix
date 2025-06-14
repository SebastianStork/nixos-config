{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.syncthing;
  tailscaleCfg = config.custom.services.tailscale;
in
{
  options.custom.services.syncthing = {
    enable = lib.mkEnableOption "";
    isServer = lib.mkEnableOption "";
    deviceId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    syncPort = lib.mkOption {
      type = lib.types.port;
      default = 22000;
    };
    gui = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8384;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = tailscaleCfg.enable;
        message = "syncthing requires tailscale";
      }
    ];

    meta.ports.list = [
      cfg.syncPort
      cfg.gui.port
    ];

    services.syncthing = {
      enable = true;

      user = lib.mkIf (!cfg.isServer) "seb";
      group = lib.mkIf (!cfg.isServer) "users";
      dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

      guiAddress = lib.mkIf cfg.isServer "127.0.0.1:${toString cfg.gui.port}";

      settings = {
        # Get the devices and their ids from the configs of the other hosts
        devices =
          self.nixosConfigurations
          |> lib.filterAttrs (name: _: name != config.networking.hostName)
          |> lib.filterAttrs (_: value: value.config.custom.services.syncthing.enable)
          |> lib.mapAttrs (
            name: value: {
              id = value.config.custom.services.syncthing.deviceId;
              addresses = [ "tcp://${name}.${tailscaleCfg.domain}:${toString cfg.syncPort}" ];
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
          listenAddress = "tcp://0.0.0.0:${toString cfg.syncPort}";
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
          autoUpgradeIntervalH = 0;
        };
      };
    };

    custom.services.gatus.endpoints = lib.mkIf cfg.isServer {
      "Syncthing" = {
        group = "Private";
        url = "tcp://${config.networking.hostName}.${tailscaleCfg.domain}:22000";
      };
      "Syncthing GUI" = {
        group = "Private";
        url = "https://${cfg.gui.domain}/rest/noauth/health";
        extraConditions = [ "[BODY].status == OK" ];
      };
    };
  };
}
