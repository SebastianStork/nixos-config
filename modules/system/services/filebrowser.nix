{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.services.filebrowser;
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/filebrowser.nix" ];

  options.custom.services.filebrowser = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 44093;
    };
  };

  config = lib.mkIf cfg.enable {
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

    custom.services.resticBackups.filebrowser = lib.mkIf cfg.doBackups {
      conflictingService = "filebrowser.service";
      extraConfig.paths = with config.services.filebrowser.settings; [
        database
        root
      ];
    };
  };
}
