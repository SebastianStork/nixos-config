{ config, pkgs, ... }:
{
  sops.secrets = {
    "container/onlyoffice/tailscale-auth-key" = { };
    "container/onlyoffice/jwt-secret" = { };
  };

  virtualisation.oci-containers.containers = {
    onlyoffice = {
      image = "onlyoffice/documentserver";
      environmentFiles = [
        # Contains "JWT_SECRET=<token>"
        config.sops.secrets."container/onlyoffice/jwt-secret".path
      ];
    };

    tailscale-onlyoffice =
      let
        configPath = pkgs.writeTextFile {
          name = "config";
          destination = "/tailscale-serve.json";
          text = builtins.toJSON {
            TCP."443".HTTPS = true;
            Web."onlyoffice.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:80";
          };
        };
      in
      {
        image = "ghcr.io/tailscale/tailscale:latest";
        environment = {
          TS_HOSTNAME = "onlyoffice";
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/tailscale-serve.json";
          TS_USERSPACE = "true"; # https://github.com/tailscale/tailscale/issues/11372
        };
        environmentFiles = [
          # Contains "TS_AUTHKEY=<token>"
          config.sops.secrets."container/onlyoffice/tailscale-auth-key".path
        ];
        volumes = [
          "/var/lib/tailscale-onlyoffice:/var/lib/tailscale"
          "${configPath}:/config"
        ];
        extraOptions = [ "--network=container:onlyoffice" ];
        dependsOn = [ "onlyoffice" ];
      };
  };
}
