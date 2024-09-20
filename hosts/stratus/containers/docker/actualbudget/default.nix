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
      image = "ghcr.io/actualbudget/actual-server@sha256:90a670b73ce539ca4bf70e3740756f106ec815d3933cabf2414ae2e26e031d65";
      volumes = [ "/data/${serviceName}:/data" ];
    };

    "tailscale-${serviceName}" = {
      environment.TS_HOSTNAME = subdomain;
      volumes = [ "${configPath}:/config" ];
    };
  };
}
