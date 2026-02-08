{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.syncthing;
  netCfg = config.custom.networking;

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
      default = "${self}/hosts/${netCfg.hostName}/keys/syncthing.id" |> lib.readFile |> lib.trim;
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
        assertion = cfg.isServer -> (cfg.gui.domain != null);
        message = "Syncthing requires `gui.domain` to be set when `isServer` is enabled";
      }
      {
        assertion = (cfg.gui.domain != null) -> (self.lib.isPrivateDomain cfg.gui.domain);
        message = self.lib.mkUnprotectedMessage "Syncthing-GUI";
      }
    ];

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

        settings =
          let
            hosts =
              self.allHosts
              |> lib.filterAttrs (_: host: host.config.networking.hostName != config.networking.hostName)
              |> lib.filterAttrs (_: host: host.config.custom.services.syncthing.enable);
          in
          {
            devices =
              hosts
              |> lib.mapAttrs (
                _: host: {
                  id = host.config.custom.services.syncthing.deviceId;
                  addresses = lib.singleton "tcp://${host.config.custom.networking.overlay.address}:${toString host.config.custom.services.syncthing.syncPort}";
                }
              );

            folders =
              cfg.folders
              |> self.lib.genAttrs (folder: {
                path = "${dataDir}/${folder}";
                devices =
                  hosts
                  |> lib.filterAttrs (_: host: host.config.custom.services.syncthing.folders |> lib.elem folder)
                  |> lib.attrNames;
              });

            options = {
              listenAddress = "tcp://${netCfg.overlay.address}:${toString cfg.syncPort}";
              globalAnnounceEnabled = false;
              localAnnounceEnabled = false;
              relaysEnabled = false;
              natEnabled = false;
              urAccepted = -1;
              autoUpgradeIntervalH = 0;
            };
          };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        port = cfg.syncPort;
        proto = "tcp";
        group = "syncthing";
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.gui.domain}.port = lib.mkIf (cfg.gui.domain != null) cfg.gui.port;

        restic.backups.syncthing = lib.mkIf cfg.doBackups {
          conflictingService = "syncthing.service";
          paths = [ dataDir ];
          extraConfig.exclude = [ "${dataDir}/Downloads" ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
