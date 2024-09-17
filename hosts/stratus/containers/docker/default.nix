{ config, lib, ... }:
let
  containers = lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./.);
in
{
  imports = lib.mapAttrsToList (name: _: ./${name}) containers;

  sops.secrets = lib.mapAttrs' (
    name: _: lib.nameValuePair "container/${name}/tailscale-auth-key" { }
  ) containers;

  virtualisation.oci-containers = {
    backend = "docker";

    containers = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "tailscale-${name}" {
        image = "ghcr.io/tailscale/tailscale:latest";
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/tailscale-serve.json";
          TS_USERSPACE = "true"; # https://github.com/tailscale/tailscale/issues/11372
        };
        environmentFiles = [
          # Contains "TS_AUTHKEY=<token>"
          config.sops.secrets."container/${name}/tailscale-auth-key".path
        ];
        volumes = [ "/var/lib/tailscale-${name}:/var/lib/tailscale" ];
        extraOptions = [ "--network=container:${name}" ];
        dependsOn = [ name ];
      }
    ) containers;
  };
}
