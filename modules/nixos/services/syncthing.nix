{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.syncthing;
  netCfg = config.custom.networking;

  inherit (config.services.syncthing) dataDir;
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

    certFile = lib.mkOption {
      type = lib.types.nullOr self.lib.types.existingPath;
      default = null;
    };
    keyFile = lib.mkOption {
      type = lib.types.nullOr self.lib.types.existingPath;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = (cfg.gui.domain != null) -> (self.lib.isPrivateDomain cfg.gui.domain);
      message = self.lib.mkUnprotectedMessage "Syncthing-GUI";
    };

    sops.secrets = {
      "syncthing/cert" = lib.mkIf (cfg.certFile == null) {
        owner = config.services.syncthing.user;
        restartUnits = [ "syncthing.service" ];
      };
      "syncthing/key" = lib.mkIf (cfg.keyFile == null) {
        owner = config.services.syncthing.user;
        restartUnits = [ "syncthing.service" ];
      };
    };

    environment.etc = {
      "syncthing/cert.pem" = lib.mkIf (cfg.certFile != null) {
        source = cfg.certFile;
        mode = "0644";
        user = config.services.syncthing.user;
      };
      "syncthing/key.pem" = lib.mkIf (cfg.keyFile != null) {
        source = cfg.keyFile;
        mode = "0600";
        user = config.services.syncthing.user;
      };
    };

    services = {
      syncthing = {
        enable = true;

        user = lib.mkIf (!cfg.isServer) "seb";
        group = lib.mkIf (!cfg.isServer) "users";
        dataDir = lib.mkIf (!cfg.isServer) "/home/seb";

        guiAddress = "localhost:${toString cfg.gui.port}";

        cert =
          if (cfg.certFile != null) then
            "/etc/syncthing/cert.pem"
          else
            config.sops.secrets."syncthing/cert".path;
        key =
          if (cfg.keyFile != null) then
            "/etc/syncthing/key.pem"
          else
            config.sops.secrets."syncthing/key".path;

        settings =
          let
            hosts =
              allHosts
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

            gui.insecureSkipHostcheck = true;
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
          extraConfig.exclude = [
            "${dataDir}/Downloads"
            "${dataDir}/Projects"
          ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.services.${cfg.gui.domain} = lib.mkIf (cfg.gui.domain != null) {
        name = "Syncthing";
        icon = "sh:syncthing";
      };
    };
  };
}
