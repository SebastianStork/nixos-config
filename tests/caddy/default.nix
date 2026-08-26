{ self, lib, ... }:
let
  publicDomain = "app.sprouted.cloud";
  serverPrivateDomain = "server-app.${self.lib.privateDomain}";
  agentPrivateDomain = "agent-app.${self.lib.privateDomain}";
  privateDomains = [
    serverPrivateDomain
    agentPrivateDomain
  ];

  publicBody = "public-reverse-proxy-ok";
  serverPrivateBody = "server-private-file-server-ok";
  agentPrivateBody = "agent-private-file-server-ok";
in
{
  imports = [ (import ../common.nix ./.) ];

  nodes = {
    caddy =
      { config, pkgs, ... }:
      {
        custom = {
          networking = {
            overlay = {
              address = "10.254.250.2";
              isLighthouse = true;
              role = "server";
            };
            underlay = {
              cidr = "192.168.0.2/16";
              isPublic = true;
            };
          };

          services.caddy.virtualHosts = {
            ${publicDomain} = {
              port = 8080;
              extraConfig = "tls internal";
            };
            ${serverPrivateDomain} = {
              extraConfig = ''
                route {
                  respond "${serverPrivateBody}"
                }
              '';
              allowedGroups = [
                "client"
                "server"
              ];
            };
            ${agentPrivateDomain} = {
              extraConfig = ''
                handle {
                  respond "${agentPrivateBody}"
                }
              '';
              allowedHosts = [ "overlayAgent" ];
            };
          };
        };

        services.static-web-server = {
          enable = true;
          listen = "127.0.0.1:8080";
          root = pkgs.writeTextDir "index.html" publicBody;
        };

        sops.secrets = lib.mkForce { };
        security.acme.defaults.credentialFiles = lib.mkForce { };
        systemd = {
          services =
            privateDomains
            |> lib.concatMap (domain: [
              {
                name = "acme-${domain}";
                value.enable = lib.mkForce false;
              }
              {
                name = "acme-order-renew-${domain}";
                value.enable = lib.mkForce false;
              }
            ])
            |> builtins.listToAttrs;
          timers =
            privateDomains
            |> lib.map (domain: {
              name = "acme-renew-${domain}";
              value.enable = lib.mkForce false;
            })
            |> builtins.listToAttrs;
          tmpfiles.rules =
            let
              mkCertRules =
                domain:
                let
                  certDir = config.security.acme.certs.${domain}.directory;
                  selfSignedCert =
                    pkgs.runCommand "caddy-test-cert-${domain}" { nativeBuildInputs = [ pkgs.openssl ]; }
                      ''
                        mkdir -p $out
                        openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
                          -keyout $out/key.pem -out $out/fullchain.pem \
                          -subj "/CN=${domain}" -addext "subjectAltName=DNS:${domain}"
                      '';
                in
                [
                  "d ${certDir} 0750 acme caddy - -"
                  "C ${certDir}/fullchain.pem 0644 acme caddy - ${selfSignedCert}/fullchain.pem"
                  "C ${certDir}/key.pem 0640 acme caddy - ${selfSignedCert}/key.pem"
                ];
            in
            [ "d /var/lib/acme 0755 acme acme - -" ] ++ lib.concatMap mkCertRules privateDomains;
        };
      };

    overlayClient =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.curl ];
        custom.networking = {
          overlay = {
            address = "10.254.250.3";
            role = "client";
          };
          underlay.cidr = "192.168.0.3/16";
        };
      };

    overlayServer =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.curl ];
        custom.networking = {
          overlay = {
            address = "10.254.250.5";
            role = "server";
          };
          underlay.cidr = "192.168.0.5/16";
        };
      };

    overlayAgent =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.curl ];
        custom.networking = {
          overlay = {
            address = "10.254.250.6";
            role = "agent";
          };
          underlay.cidr = "192.168.0.6/16";
        };
      };

    externalClient =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.curl ];
        custom = {
          services.nebula.enable = lib.mkForce false;
          networking = {
            overlay.role = "client";
            underlay.cidr = "192.168.0.4/16";
          };
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      netCfg = nodes.caddy.custom.networking;

      curl = "curl --fail --silent --show-error --insecure --max-time 10";
    in
    ''
      with subtest("Readiness"):
        caddy.start()
        caddy.wait_for_unit("${netCfg.overlay.systemdUnit}")
        caddy.wait_for_unit("static-web-server.socket")
        caddy.wait_for_unit("caddy.service")
        overlayClient.start()
        overlayClient.wait_for_unit("${nodes.overlayClient.custom.networking.overlay.systemdUnit}")
        overlayServer.start()
        overlayServer.wait_for_unit("${nodes.overlayServer.custom.networking.overlay.systemdUnit}")
        overlayAgent.start()
        overlayAgent.wait_for_unit("${nodes.overlayAgent.custom.networking.overlay.systemdUnit}")
        externalClient.start()
        externalClient.wait_for_unit("multi-user.target")

      with subtest("Overlay client reaches private and public hosts"):
        overlayClient.succeed("${curl} --resolve ${publicDomain}:443:${netCfg.underlay.address} https://${publicDomain} | grep -q '${publicBody}'")
        overlayClient.succeed("${curl} --resolve ${serverPrivateDomain}:443:${netCfg.overlay.address} https://${serverPrivateDomain} | grep -q '${serverPrivateBody}'")
        overlayClient.succeed("${curl} --resolve ${agentPrivateDomain}:443:${netCfg.overlay.address} https://${agentPrivateDomain} | grep -q '${agentPrivateBody}'")

      with subtest("Agent reaches only agent-accessible private host"):
        overlayAgent.succeed("${curl} --resolve ${agentPrivateDomain}:443:${netCfg.overlay.address} https://${agentPrivateDomain} | grep -q '${agentPrivateBody}'")
        overlayAgent.fail("${curl} --resolve ${serverPrivateDomain}:443:${netCfg.overlay.address} https://${serverPrivateDomain}")

      with subtest("Server reaches only server-accessible private host"):
        overlayServer.fail("${curl} --resolve ${agentPrivateDomain}:443:${netCfg.overlay.address} https://${agentPrivateDomain}")
        overlayServer.succeed("${curl} --resolve ${serverPrivateDomain}:443:${netCfg.overlay.address} https://${serverPrivateDomain} | grep -q '${serverPrivateBody}'")

      with subtest("External client reaches only the public host"):
        externalClient.succeed("${curl} --resolve ${publicDomain}:443:${netCfg.underlay.address} https://${publicDomain} | grep -q '${publicBody}'")
        externalClient.fail("${curl} --resolve ${serverPrivateDomain}:443:${netCfg.overlay.address} https://${serverPrivateDomain} | grep -q '${serverPrivateBody}'")
        externalClient.fail("${curl} --resolve ${serverPrivateDomain}:443:${netCfg.underlay.address} https://${serverPrivateDomain} | grep -q '${serverPrivateBody}'")
    '';
}
