{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.syncthing;
  tailscaleCfg = config.custom.services.tailscale;

  useStaticTls = config.custom.sops.secrets |> lib.hasAttr "syncthing";
in
{
  options.custom.services.syncthing = {
    enable = lib.mkEnableOption "";
    isServer = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
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
      {
        assertion = cfg.doBackups -> cfg.isServer;
        message = "syncthing backups can only be performed on a server";
      }
    ];

    meta = {
      domains.list = lib.mkIf cfg.isServer [ cfg.gui.domain ];
      ports.list = [
        cfg.syncPort
        cfg.gui.port
      ];
    };

    sops.secrets = lib.mkIf useStaticTls {
      "syncthing/cert".owner = config.services.syncthing.user;
      "syncthing/key".owner = config.services.syncthing.user;
    };

    services.syncthing = {
      enable = true;

      user = lib.mkIf (!cfg.isServer) "seb";
      group = lib.mkIf (!cfg.isServer) "users";
      dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

      guiAddress = lib.mkIf cfg.isServer "127.0.0.1:${builtins.toString cfg.gui.port}";

      cert = lib.mkIf useStaticTls config.sops.secrets."syncthing/cert".path;
      key = lib.mkIf useStaticTls config.sops.secrets."syncthing/key".path;

      settings = {
        # Get the devices and their ids from the configs of the other hosts
        devices =
          self.nixosConfigurations
          |> lib.filterAttrs (name: _: name != config.networking.hostName)
          |> lib.filterAttrs (_: value: value.config.custom.services.syncthing.enable)
          |> lib.mapAttrs (
            name: value: {
              id = value.config.custom.services.syncthing.deviceId;
              addresses = [ "tcp://${name}.${tailscaleCfg.domain}:${builtins.toString cfg.syncPort}" ];
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
          listenAddress = "tcp://0.0.0.0:${builtins.toString cfg.syncPort}";
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
          autoUpgradeIntervalH = 0;
        };
      };
    };

    custom.services.resticBackups.syncthing = lib.mkIf cfg.doBackups {
      conflictingService = "syncthing.service";
      extraConfig.paths = [ config.services.syncthing.dataDir ];
    };
  };
}
