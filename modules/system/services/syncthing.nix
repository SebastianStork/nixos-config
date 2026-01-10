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
    folders = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
      default = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Videos"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.services.nebula.node.enable;
        message = "Syncthing requires nebula";
      }
      {
        assertion = cfg.isServer -> (cfg.gui.domain != null);
        message = "Running syncthing on a server requires `gui.domain` to be set";
      }
      {
        assertion = (cfg.gui.domain != null) -> (lib'.isPrivateDomain cfg.gui.domain);
        message = lib'.mkUnprotectedMessage "Syncthing-GUI";
      }
    ];

    meta = {
      domains.local = lib.mkIf (cfg.gui.domain != null) [ cfg.gui.domain ];
      ports = {
        tcp = [
          cfg.syncPort
          cfg.gui.port
        ];
        udp = [ cfg.syncPort ];
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

    services = {
      syncthing = {
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
              _: value: {
                id = value.config.custom.services.syncthing.deviceId;
                addresses = [
                  "tcp://${value.config.custom.services.nebula.node.address}:${toString cfg.syncPort}"
                ];
              }
            );

          folders =
            cfg.folders
            |> lib'.genAttrs (name: {
              path = "${dataDir}/${name}";
              devices = config.services.syncthing.settings.devices |> lib.attrNames;
            });

          options = {
            listenAddress = "tcp://${config.custom.services.nebula.node.address}:${toString cfg.syncPort}";
            globalAnnounceEnabled = false;
            localAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
            urAccepted = -1;
            autoUpgradeIntervalH = 0;
          };
        };
      };

      nebula.networks.mesh.firewall.inbound =
        config.services.syncthing.settings.devices
        |> lib.attrNames
        |> lib.map (name: {
          port = cfg.syncPort;
          proto = "tcp";
          host = name;
        });
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.gui.domain}.port = lib.mkIf (cfg.gui.domain != null) cfg.gui.port;

        restic.backups.syncthing = lib.mkIf cfg.doBackups {
          conflictingService = "syncthing.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
