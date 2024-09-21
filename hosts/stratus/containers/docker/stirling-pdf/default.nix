{
  config,
  pkgs,
  lib,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "pdf";

  serveConfig = builtins.toJSON {
    TCP."443".HTTPS = true;
    Web."${subdomain}.${config.networking.domain}:443".Handlers."/".Proxy = "http://127.0.0.1:8080";
  };
  configPath = pkgs.writeTextDir "tailscale-serve.json" serveConfig;
in
{
  virtualisation.oci-containers.containers = {
    ${serviceName} = {
      image = "frooodle/s-pdf@sha256:5b9c9443e6eb0fa23b39475d68741d80826249193df231d6859ecda0f0aedd8d";
      environment = {
        LANGS = "de_DE";
        SYSTEM_SHOWUPDATE = "false";
      };
      volumes = [
        "/data/stirling-pdf/tessdata:/usr/share/tessdata"
        "/data/stirling-pdf/configs:/configs"
      ];
    };

    "tailscale-${serviceName}" = {
      environment.TS_HOSTNAME = subdomain;
      volumes = [ "${configPath}:/config" ];
    };
  };
}
