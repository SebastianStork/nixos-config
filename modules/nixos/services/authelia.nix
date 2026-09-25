{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.authelia;
  instance = config.services.authelia.instances.main;
  dataDir = "/var/lib/authelia-main";
in
{
  options.custom.services.authelia = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9091;
    };
    user = {
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
      displayName = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
      email = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "authelia/storage-encryption-key" = {
          owner = instance.user;
          restartUnits = [ "authelia-main.service" ];
        };
        "authelia/password-hash".restartUnits = [ "authelia-main.service" ];
      };

      templates."authelia-users.yml" = {
        owner = instance.user;
        restartUnits = [ "authelia-main.service" ];
        file =
          {
            users.${cfg.user.name} = {
              disabled = false;
              displayname = cfg.user.displayName;
              password = config.sops.placeholder."authelia/password-hash";
              inherit (cfg.user) email;
            };
          }
          |> (pkgs.formats.yaml { }).generate "authelia-users.yml";
      };
    };

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        manual = true;
        storageEncryptionKeyFile = config.sops.secrets."authelia/storage-encryption-key".path;
      };
      settings = {
        server.address = "tcp://127.0.0.1:${lib.toString cfg.port}/";
        log.level = "info";

        authentication_backend = {
          password_reset.disable = true;
          password_change.disable = true;
          file = {
            path = config.sops.templates."authelia-users.yml".path;
            watch = false;
          };
        };

        access_control.default_policy = "one_factor";

        session.cookies = lib.singleton {
          domain = config.networking.domain;
          authelia_url = "https://${cfg.domain}";
        };

        storage.local.path = "${dataDir}/db.sqlite3";
        notifier.filesystem.filename = "${dataDir}/notifications.txt";
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain} = {
        extraConfig = ''
          @forwardAuth path /api/authz/forward-auth
          reverse_proxy @forwardAuth localhost:${lib.toString cfg.port} {
            header_up X-Forwarded-Host {http.request.header.X-Forwarded-Host}
          }

          reverse_proxy localhost:${lib.toString cfg.port}
        '';
        extraAllowedHosts =
          allHosts
          |> lib.attrValues
          |> lib.filter (
            host:
            host.config.custom.services.caddy.virtualHosts
            |> lib.attrValues
            |> lib.any (vHost: vHost.forwardAuth.enable)
          )
          |> lib.map (host: host.config.networking.hostName);
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Authelia";
        icon = "sh:authelia";
      };
    };
  };
}
