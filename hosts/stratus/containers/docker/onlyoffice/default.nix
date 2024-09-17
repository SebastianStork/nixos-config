{ config, pkgs, ... }:
let
  serviceName = "onlyoffice";
  subdomain = "office";

  serveConfig = builtins.toJSON {
    TCP."443".HTTPS = true;
    Web."${subdomain}.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:80";
  };
  configPath = pkgs.writeTextDir "tailscale-serve.json" serveConfig;
in
{
  sops.secrets."container/${serviceName}/jwt-secret" = { };

  virtualisation.oci-containers.containers = {
    ${serviceName} = {
      image = "onlyoffice/documentserver";
      environmentFiles = [
        # Contains "JWT_SECRET=<token>"
        config.sops.secrets."container/${serviceName}/jwt-secret".path
      ];
    };

    "tailscale-${serviceName}" = {
      environment.TS_HOSTNAME = subdomain;
      volumes = [ "${configPath}:/config" ];
    };
  };
}
