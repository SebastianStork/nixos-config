{ config, pkgs, ... }:
{
  sops.secrets."container/actualbudget/tailscale-auth-key" = { };

  virtualisation.oci-containers.containers = {
    actualbudget = {
      image = "ghcr.io/actualbudget/actual-server:latest";
      volumes = [ "/data/actualbudget:/data" ];
    };

    tailscale-actualbudget =
      let
        configPath = pkgs.writeTextFile {
          name = "config";
          destination = "/tailscale-serve.json";
          text = builtins.toJSON {
            TCP."443".HTTPS = true;
            Web."actualbudget.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:5006";
          };
        };
      in
      {
        image = "ghcr.io/tailscale/tailscale:latest";
        environment = {
          TS_HOSTNAME = "actualbudget";
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/tailscale-serve.json";
          TS_USERSPACE = "true"; # https://github.com/tailscale/tailscale/issues/11372
        };
        environmentFiles = [
          # Contains "TS_AUTHKEY=<token>"
          config.sops.secrets."container/actualbudget/tailscale-auth-key".path
        ];
        volumes = [
          "/var/lib/tailscale-actualbudget:/var/lib/tailscale"
          "${configPath}:/config"
        ];
        extraOptions = [ "--network=container:actualbudget" ];
        dependsOn = [ "actualbudget" ];
      };
  };
}
