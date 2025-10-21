{
  config,
  options,
  modulesPath,
  inputs,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.memos;

  dataDir = config.services.memos.settings.MEMOS_DATA;
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/memos.nix" ];

  options.custom.services.memos = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5230;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !lib.pathExists "${modulesPath}/services/misc/memos.nix";
        message = "TODO: Use memos module from stable nixpkgs";
      }
      {
        assertion = lib.versionOlder lib.version "25.11";
        message = "TODO: Use memos package from stable nixpkgs";
      }
    ];

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.memos = {
      enable = true;
      package = pkgs-unstable.memos;
      settings = options.services.memos.settings.default // {
        MEMOS_PORT = toString cfg.port;
        MEMOS_INSTANCE_URL = "https://${cfg.domain}";
      };
    };

    custom = {
      services.resticBackups.memos = lib.mkIf cfg.doBackups {
        conflictingService = "memos.service";
        paths = [ dataDir ];
      };

      persist.directories = [ dataDir ];
    };
  };
}
