{
  config,
  pkgs,
  lib,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
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
      image = "onlyoffice/documentserver@sha256:b9e3c35eab182d3de822a53b109b0f27070f6eacea3b1388b9c50d1182f638f2";
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
