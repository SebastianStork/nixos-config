{
  config,
  modulesPath,
  inputs,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.filebrowser;

  dataDir = "/var/lib/filebrowser";
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/filebrowser.nix" ];

  options.custom.services.filebrowser = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 44093;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib'.isTailscaleDomain cfg.domain;
        message = "Filebrowser isn't yet configured with access controll.";
      }
      {
        assertion = !lib.pathExists "${modulesPath}/services/web-apps/filebrowser.nix";
        message = "TODO: Use filebrowser module from stable nixpkgs";
      }
    ];

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.filebrowser = {
      enable = true;
      settings = {
        inherit (cfg) port;
        noauth = true;
      };
    };

    custom = {
      services.resticBackups.filebrowser = lib.mkIf cfg.doBackups {
        conflictingService = "filebrowser.service";
        paths = [ dataDir ];
      };

      persist.directories = [ dataDir ];
    };
  };
}
