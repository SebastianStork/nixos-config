{ config, pkgs, ... }:
let
  serviceName = "onlyoffice";
  subdomain = "office";
in
{
  sops.secrets = {
    "container/${serviceName}/tailscale-auth-key" = { };
    "container/${serviceName}/jwt-secret" = { };
  };

  virtualisation.oci-containers.containers = {
    ${serviceName} = {
      image = "onlyoffice/documentserver";
      environmentFiles = [
        # Contains "JWT_SECRET=<token>"
        config.sops.secrets."container/${serviceName}/jwt-secret".path
      ];
    };

    "tailscale-${serviceName}" =
      let
        configPath = pkgs.writeTextFile {
          name = "config";
          destination = "/tailscale-serve.json";
          text = builtins.toJSON {
            TCP."443".HTTPS = true;
            Web."${subdomain}.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:80";
          };
        };
      in
      {
        image = "ghcr.io/tailscale/tailscale:latest";
        environment = {
          TS_HOSTNAME = subdomain;
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/tailscale-serve.json";
          TS_USERSPACE = "true"; # https://github.com/tailscale/tailscale/issues/11372
        };
        environmentFiles = [
          # Contains "TS_AUTHKEY=<token>"
          config.sops.secrets."container/${serviceName}/tailscale-auth-key".path
        ];
        volumes = [
          "/var/lib/tailscale-${serviceName}:/var/lib/tailscale"
          "${configPath}:/config"
        ];
        extraOptions = [ "--network=container:${serviceName}" ];
        dependsOn = [ serviceName ];
      };
  };
}
