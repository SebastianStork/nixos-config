{ config, lib, ... }:
let
  cfg = config.custom.web-services.privatebin;
in
{
  options.custom.web-services.privatebin = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    branding.name = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "PrivateBin";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      privatebin = {
        enable = true;
        settings.main = {
          basepath = "https://${cfg.domain}";
          inherit (cfg.branding) name;
        };
      };

      phpfpm.pools.privatebin.settings."listen.group" = "caddy";
    };

    systemd.services.caddy = {
      wants = [ "phpfpm-privatebin.service" ];
      after = [ "phpfpm-privatebin.service" ];
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
        root * ${config.services.privatebin.package}
        route {
          @root path /
          rewrite @root /index.php
          @missing not file
          rewrite @missing /index.php
          @index path /index.php
          php_fastcgi @index unix//run/phpfpm/privatebin.sock
          file_server
        }
      '';

      meta.sites.${cfg.domain} = {
        title = "PrivateBin";
        icon = "privatebin";
      };
    };
  };
}
