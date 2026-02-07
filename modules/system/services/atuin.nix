{ config, lib, ... }:
let
  cfg = config.custom.services.atuin;
in
{
  options.custom.services.atuin = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8849;
    };
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      enable = true;
      openRegistration = true;
      inherit (cfg) port;
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
