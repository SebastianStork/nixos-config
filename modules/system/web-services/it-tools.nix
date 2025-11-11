{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.it-tools;
in
{
  options.custom.services.it-tools = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    meta.domains.local = [ cfg.domain ];

    custom.services.caddy.virtualHosts.${cfg.domain}.files = "${pkgs.it-tools}/lib";
  };
}
