{ lib, ... }:
let
  publicDomain = "app.sprouted.cloud";
  privateDomain = "app.splitleaf.de";
  publicBody = "public-reverse-proxy-ok";
  privateBody = "private-file-server-ok";
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
            ${privateDomain}.files = pkgs.writeTextDir "index.html" privateBody;
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
          services."acme-${privateDomain}".enable = lib.mkForce false;
          services."acme-order-renew-${privateDomain}".enable = lib.mkForce false;
          timers."acme-renew-${privateDomain}".enable = lib.mkForce false;
          tmpfiles.rules =
            let
              certDir = config.security.acme.certs.${privateDomain}.directory;
              selfSignedCert = pkgs.runCommand "caddy-test-cert" { nativeBuildInputs = [ pkgs.openssl ]; } ''
                mkdir -p $out
                openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
                  -keyout $out/key.pem -out $out/fullchain.pem \
                  -subj "/CN=${privateDomain}" -addext "subjectAltName=DNS:${privateDomain}"
              '';
            in
            [
              "d /var/lib/acme 0755 acme acme - -"
              "d ${certDir} 0750 acme caddy - -"
              "C ${certDir}/fullchain.pem 0644 acme caddy - ${selfSignedCert}/fullchain.pem"
              "C ${certDir}/key.pem 0640 acme caddy - ${selfSignedCert}/key.pem"
            ];
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
        externalClient.start()
        externalClient.wait_for_unit("multi-user.target")

      with subtest("Overlay client reaches private and public hosts"):
        overlayClient.succeed("${curl} --resolve ${publicDomain}:443:${netCfg.underlay.address} https://${publicDomain} | grep -q '${publicBody}'")
        overlayClient.succeed("${curl} --resolve ${privateDomain}:443:${netCfg.overlay.address} https://${privateDomain} | grep -q '${privateBody}'")

      with subtest("External client reaches only the public host"):
        externalClient.succeed("${curl} --resolve ${publicDomain}:443:${netCfg.underlay.address} https://${publicDomain} | grep -q '${publicBody}'")
        externalClient.fail("${curl} --resolve ${privateDomain}:443:${netCfg.overlay.address} https://${privateDomain} | grep -q '${privateBody}'")
        externalClient.fail("${curl} --resolve ${privateDomain}:443:${netCfg.underlay.address} https://${privateDomain} | grep -q '${privateBody}'")
    '';
}
