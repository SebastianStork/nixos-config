{ config, lib, ... }:
let
  containers = lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./.);
in
{
  imports = lib.mapAttrsToList (name: _: ./${name}) containers;

  sops.secrets."container/tailscale-auth-key" = { };

  virtualisation.oci-containers = {
    backend = "docker";

    containers = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "tailscale-${name}" {
        image = "ghcr.io/tailscale/tailscale@sha256:da35f0fbeb3037754049e3b079cb30c58c140576a50b54be107c0ff6ad0ec0e9";
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/tailscale-serve.json";
          TS_USERSPACE = "true"; # https://github.com/tailscale/tailscale/issues/11372
        };
        environmentFiles = [
          # Contains "TS_AUTHKEY=<token>"
          config.sops.secrets."container/tailscale-auth-key".path
        ];
        volumes = [ "/var/lib/tailscale-${name}:/var/lib/tailscale" ];
        extraOptions = [ "--network=container:${name}" ];
        dependsOn = [ name ];
      }
    ) containers;
  };
}
