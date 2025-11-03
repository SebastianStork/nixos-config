{
  config,
  self,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.syncthing;

  inherit (config.services.syncthing) dataDir;

  useSopsSecrets = config.custom.sops.secrets |> lib.hasAttr "syncthing";
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
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
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
        assertion = config.custom.services.tailscale.enable;
        message = "Syncthing requires tailscale";
      }
      {
        assertion = cfg.isServer -> (cfg.gui.domain != null);
        message = "Running syncthing on a server requires `gui.domain` to be set";
      }
      {
        assertion = (cfg.gui.domain != null) -> (lib'.isTailscaleDomain cfg.gui.domain);
        message = lib'.mkUnprotectedMessage "Syncthing-GUI";
      }
    ];

    meta = {
      domains.list = lib.mkIf (cfg.gui.domain != null) [ cfg.gui.domain ];
      ports = {
        tcp.list = [
          cfg.syncPort
          cfg.gui.port
        ];
        udp.list = [ cfg.syncPort ];
      };
    };

    sops.secrets = lib.mkIf useSopsSecrets {
      "syncthing/cert" = {
        owner = config.services.syncthing.user;
        restartUnits = [ "syncthing.service" ];
      };
      "syncthing/key" = {
        owner = config.services.syncthing.user;
        restartUnits = [ "syncthing.service" ];
      };
    };

    services.syncthing = {
      enable = true;

      user = lib.mkIf (!cfg.isServer) "seb";
      group = lib.mkIf (!cfg.isServer) "users";
      dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

      guiAddress = "localhost:${toString cfg.gui.port}";

      cert = lib.mkIf useSopsSecrets config.sops.secrets."syncthing/cert".path;
      key = lib.mkIf useSopsSecrets config.sops.secrets."syncthing/key".path;

      settings = {
        # Get the devices and their ids from the configs of the other hosts
        devices =
          self.nixosConfigurations
          |> lib.filterAttrs (name: _: name != config.networking.hostName)
          |> lib.filterAttrs (_: value: value.config.custom.services.syncthing.enable)
          |> lib.mapAttrs (
            name: value: {
              id = value.config.custom.services.syncthing.deviceId;
              addresses = [ "tcp://${name}.${config.custom.services.tailscale.domain}:${toString cfg.syncPort}" ];
            }
          );

        folders =
          let
            genFolders =
              folders:
              folders
              |> lib'.genAttrs (name: {
                path = "${dataDir}/${name}";
                ignorePerms = false;
                devices = config.services.syncthing.settings.devices |> lib.attrNames;
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

    custom = {
      services.restic.backups.syncthing = lib.mkIf cfg.doBackups {
        conflictingService = "syncthing.service";
        paths = [ dataDir ];
      };

      persist.directories = [ dataDir ];
    };
  };
}
