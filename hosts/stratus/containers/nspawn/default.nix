{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  containers = lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./.);
  dataDirOf = name: "/data/${name}";
in
{
  imports = lib.mapAttrsToList (name: _: ./${name}) containers;

  sops.secrets = {
    "container/tailscale-auth-key" = { };
    "restic/environment" = { };
    "restic/password" = { };
    "healthchecks-ping-key" = { };
  };

  systemd.tmpfiles.rules = lib.flatten (
    lib.mapAttrsToList (name: _: [
      "d ${dataDirOf name} - - -"
      "d /var/lib/tailscale-${name} - - -"
    ]) containers
  );

  networking = {
    useDHCP = false;
    bridges.br0.interfaces = [ "eno1" ];
    interfaces."br0".useDHCP = true;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "br0";
    };
  };

  containers = lib.mapAttrs (name: _: {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    enableTun = true;
    hostBridge = "br0";

    bindMounts = {
      # Secrets
      "/run/secrets/tailscale-auth-key".hostPath = "/run/secrets/container/tailscale-auth-key";
      "/run/secrets/container/${name}".isReadOnly = false;
      "/run/secrets/restic".isReadOnly = false;
      "/run/secrets/healthchecks-ping-key".isReadOnly = false;

      # State
      ${dataDirOf name}.isReadOnly = false;
      "/var/lib/tailscale" = {
        hostPath = "/var/lib/tailscale-${name}";
        isReadOnly = false;
      };
    };

    specialArgs = {
      inherit inputs self;
      inherit (config.system) stateVersion;
      inherit (config.networking) domain;
      dataDir = dataDirOf name;
    };
    config =
      {
        self,
        stateVersion,
        domain,
        ...
      }:
      {
        imports = [ self.nixosModules.default ];

        system = {
          inherit stateVersion;
        };

        networking = {
          inherit domain;
          useHostResolvConf = false;
          interfaces."eth0".useDHCP = true;
        };
        services.resolved.enable = true;

        myConfig.tailscale.enable = true;
      };
  }) containers;
}
