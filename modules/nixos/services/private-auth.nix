{
  config,
  pkgs,
  lib,
  self,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.private-auth;
  instance = config.services.authelia.instances.main;
  dataDir = "/var/lib/authelia-main";

  oidcClients =
    allHosts
    |> lib.attrValues
    |> lib.concatMap (
      host: (self.lib.uncheckedHostConfig host).custom.services.private-auth.oidcClients |> lib.attrValues
    );
in
{
  options.custom.services.private-auth = {
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
    oidcClients = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              clientId = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = name;
              };
              clientName = lib.mkOption {
                type = lib.types.nonEmptyStr;
              };
              redirectUris = lib.mkOption {
                type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = lib.mkMerge [
    {
      custom.networking.overlay.accessGroups = lib.mkIf (cfg.oidcClients != { }) [
        "private-auth-client"
      ];
    }

    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = self.lib.isPrivateDomain cfg.domain;
              message = self.lib.mkInvalidConfigMessage "Private authentication service" "domain must be private";
            }
            {
              assertion =
                lib.length (oidcClients |> lib.map (client: client.clientId) |> lib.unique)
                == lib.length oidcClients;
              message = self.lib.mkInvalidConfigMessage "Private authentication service" "OIDC client IDs must be unique";
            }
          ];

          sops = {
            secrets = {
              "private-auth/storage-encryption-key" = {
                owner = instance.user;
                restartUnits = [ "authelia-main.service" ];
              };
              "private-auth/password-hash".restartUnits = [ "authelia-main.service" ];
            };

            templates."authelia-users.yml" = {
              owner = instance.user;
              restartUnits = [ "authelia-main.service" ];
              file =
                {
                  users.${cfg.user.name} = {
                    disabled = false;
                    displayname = cfg.user.displayName;
                    password = config.sops.placeholder."private-auth/password-hash";
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
              storageEncryptionKeyFile = config.sops.secrets."private-auth/storage-encryption-key".path;
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
              extraAllowedGroups = [ "private-auth-client" ];
            };

            persistence.directories = [ dataDir ];

            meta.sites.${cfg.domain} = {
              title = "Private Auth";
              icon = "authelia";
            };
          };
        }

        (lib.mkIf (oidcClients != [ ]) {
          sops.secrets = {
            "private-auth/oidc-hmac-secret" = {
              owner = instance.user;
              restartUnits = [ "authelia-main.service" ];
            };
            "private-auth/oidc-issuer-private-key" = {
              owner = instance.user;
              restartUnits = [ "authelia-main.service" ];
            };
          }
          // (
            oidcClients
            |> lib.map (
              client:
              lib.nameValuePair "private-auth/oidc-clients/${client.clientId}/client-secret-hash" {
                owner = instance.user;
                restartUnits = [ "authelia-main.service" ];
              }
            )
            |> lib.listToAttrs
          );

          services.authelia.instances.main = {
            secrets = {
              oidcHmacSecretFile = config.sops.secrets."private-auth/oidc-hmac-secret".path;
              oidcIssuerPrivateKeyFile = config.sops.secrets."private-auth/oidc-issuer-private-key".path;
            };
            settings.identity_providers.oidc.clients =
              oidcClients
              |> lib.map (client: {
                client_id = client.clientId;
                client_name = client.clientName;
                client_secret = ''{{ secret "${
                  config.sops.secrets."private-auth/oidc-clients/${client.clientId}/client-secret-hash".path
                }" }}'';
                public = false;
                authorization_policy = "one_factor";
                require_pkce = true;
                pkce_challenge_method = "S256";
                redirect_uris = client.redirectUris;
                scopes = [
                  "openid"
                  "profile"
                  "email"
                ];
                token_endpoint_auth_method = "client_secret_basic";
              });
          };
        })
      ]
    ))
  ];
}
