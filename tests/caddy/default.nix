{ self, lib, ... }:
let
  publicDomain = "public.test";
  lanEnabledDomain = "lan-enabled.${self.lib.privateDomain}";
  namedPeerDomain = "named-peer.${self.lib.privateDomain}";
  privateDomains = [
    lanEnabledDomain
    namedPeerDomain
  ];

  publicBody = "public-reverse-proxy-ok";
  lanEnabledBody = "lan-enabled-ok";
  namedPeerBody = "named-peer-ok";
in
{
  imports = [ (import ../common.nix ./.) ];

  containers = {
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
              trusted = true;
            };
          };

          services.caddy.virtualHosts = {
            ${publicDomain} = {
              port = 8080;
              extraConfig = "tls internal";
            };
            ${lanEnabledDomain} = {
              extraConfig = ''
                route {
                  respond "${lanEnabledBody}"
                }
              '';
              allowedGroups = [
                "client"
                "server"
              ];
            };
            ${namedPeerDomain} = {
              extraConfig = ''
                handle {
                  respond "${namedPeerBody}"
                }
              '';
              allowedGroups = [ ];
              extraAllowedHosts = [ "overlayAgent" ];
              allowTrustedUnderlay = false;
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

    lanClient =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.curl ];
        custom.networking = {
          overlay.enable = false;
          underlay.cidr = "192.168.0.4/16";
        };
      };
  };

  testScript =
    { containers, ... }:
    let
      netCfg = containers.caddy.custom.networking;
    in
    ''
      from shlex import join

      def request(client, domain, address):
          command = join([
              "curl", "--silent", "--show-error", "--insecure", "--max-time", "10",
              "--resolve", f"{domain}:443:{address}", "--write-out", r"\n%{http_code}",
              f"https://{domain}",
          ])
          body, status = client.succeed(command).rsplit("\n", 1)
          return int(status), body

      with subtest("Readiness"):
          caddy.start()
          caddy.wait_for_unit("${netCfg.overlay.systemdUnit}")
          caddy.wait_for_unit("static-web-server.socket")
          caddy.wait_for_unit("caddy.service")
          overlayClient.start()
          overlayClient.wait_for_unit("${containers.overlayClient.custom.networking.overlay.systemdUnit}")
          overlayServer.start()
          overlayServer.wait_for_unit("${containers.overlayServer.custom.networking.overlay.systemdUnit}")
          overlayAgent.start()
          overlayAgent.wait_for_unit("${containers.overlayAgent.custom.networking.overlay.systemdUnit}")
          lanClient.start()
          lanClient.wait_for_unit("multi-user.target")

      with subtest("Overlay client reaches the public and client-accessible hosts"):
          assert request(overlayClient, "${publicDomain}", "${netCfg.underlay.address}") == (200, "${publicBody}")
          assert request(overlayClient, "${lanEnabledDomain}", "${netCfg.overlay.address}") == (200, "${lanEnabledBody}")
          assert request(overlayClient, "${namedPeerDomain}", "${netCfg.overlay.address}")[0] == 403

      with subtest("Named peer reaches only the named-peer site"):
          assert request(overlayAgent, "${namedPeerDomain}", "${netCfg.overlay.address}") == (200, "${namedPeerBody}")
          assert request(overlayAgent, "${lanEnabledDomain}", "${netCfg.overlay.address}")[0] == 403

      with subtest("Overlay server reaches the group-accessible site but not the named-peer site"):
          assert request(overlayServer, "${lanEnabledDomain}", "${netCfg.overlay.address}") == (200, "${lanEnabledBody}")
          assert request(overlayServer, "${namedPeerDomain}", "${netCfg.overlay.address}")[0] == 403

      with subtest("Trusted LAN reaches the public and LAN-enabled hosts"):
          assert request(lanClient, "${publicDomain}", "${netCfg.underlay.address}") == (200, "${publicBody}")
          assert request(lanClient, "${lanEnabledDomain}", "${netCfg.underlay.address}") == (200, "${lanEnabledBody}")
          _, body = request(lanClient, "${namedPeerDomain}", "${netCfg.underlay.address}")
          assert "${namedPeerBody}" not in body
    '';
}
