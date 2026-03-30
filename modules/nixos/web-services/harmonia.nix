{ config, lib, ... }:
let
  cfg = config.custom.web-services.harmonia;
in
{
  options.custom.web-services.harmonia = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."harmonia/signing-key".owner = config.users.users.harmonia.name;

    services.harmonia = {
      enable = true;
      signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
      settings.bind = "127.0.0.1:${toString cfg.port}";
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
