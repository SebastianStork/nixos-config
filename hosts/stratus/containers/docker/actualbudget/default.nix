{
  config,
  pkgs,
  lib,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "budget";

  serveConfig = builtins.toJSON {
    TCP."443".HTTPS = true;
    Web."${subdomain}.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:5006";
  };
  configPath = pkgs.writeTextDir "tailscale-serve.json" serveConfig;
in
{
  imports = [ ./backup.nix ];

  virtualisation.oci-containers.containers = {
    ${serviceName} = {
      image = "ghcr.io/actualbudget/actual-server@sha256:0cf0300ed4905045ed87e8892c26fbd83cd08e8499bb81dc28deef6afeb162fb";
      volumes = [ "/data/${serviceName}:/data" ];
    };

    "tailscale-${serviceName}" = {
      environment.TS_HOSTNAME = subdomain;
      volumes = [ "${configPath}:/config" ];
    };
  };
}
