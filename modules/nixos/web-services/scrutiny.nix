{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.scrutiny;
in
{
  options.custom.web-services.scrutiny = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8466;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain;
      message = self.lib.mkUnprotectedMessage "Scrutiny";
    };

    services.scrutiny = {
      enable = true;
      settings.web.listen = {
        host = "127.0.0.1";
        inherit (cfg) port;
      };
    };

    systemd.services.scrutiny.enableStrictShellChecks = false;

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ "/var/lib/scrutiny" ];

      meta.sites.${cfg.domain} = {
        title = "Scrutiny";
        icon = "sh:scrutiny";
      };
    };
  };
}
