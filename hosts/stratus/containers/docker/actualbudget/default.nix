{ config, pkgs, ... }:
let
  serviceName = "actualbudget";
  subdomain = "budget";

  serveConfig = builtins.toJSON {
    TCP."443".HTTPS = true;
    Web."${subdomain}.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:5006";
  };
  configPath = pkgs.writeTextDir "tailscale-serve.json" serveConfig;
in
{
  virtualisation.oci-containers.containers = {
    ${serviceName} = {
      image = "ghcr.io/actualbudget/actual-server:latest";
      volumes = [ "/data/${serviceName}:/data" ];
    };

    "tailscale-${serviceName}" = {
      environment.TS_HOSTNAME = subdomain;
      volumes = [ "${configPath}:/config" ];
    };
  };
}
