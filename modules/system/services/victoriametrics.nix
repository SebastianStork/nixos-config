{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.victoriametrics;
in
{
  options.custom.services.victoriametrics = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8428;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.victoriametrics = {
      enable = true;
      package = pkgs-unstable.victoriametrics;
      listenAddress = "localhost:${builtins.toString cfg.port}";
      extraOptions = [ "-selfScrapeInterval=10s" ];
    };
  };
}
