{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.bentopdf;
in
{
  options.custom.web-services.bentopdf = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    custom = {
      services.caddy.virtualHosts.${cfg.domain}.files = pkgs.bentopdf;

      meta.sites.${cfg.domain} = {
        title = "BentoPDF";
        icon = "bentopdf";
      };
    };
  };
}
