{ config, lib, ... }:
let
  cfg = config.custom.services.stirling-pdf;
in
{
  options.custom.services.stirling-pdf = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 56191;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    virtualisation.oci-containers.containers.stirling-pdf = {
      image = "docker.stirlingpdf.com/stirlingtools/stirling-pdf";
      environment = {
        DISABLE_ADDITIONAL_FEATURES = "false";
        SYSTEM_ENABLEANALYTICS = "false";
        LANGS = "de_DE";
      };
      ports = [ "127.0.0.1:${builtins.toString cfg.port}:8080" ];
      pull = "newer";
    };
  };
}
