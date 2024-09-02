{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  containers = lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./.);
  interface = "eno1";
  dataDirOf = name: "/data/${name}";
in
{
  imports = [
    ./nextcloud
    ./paperless
  ];

  sops.secrets = lib.mapAttrs' (
    name: _: lib.nameValuePair "container/${name}/ssh-key" { }
  ) containers;

  systemd.tmpfiles.rules = lib.flatten (
    lib.mapAttrsToList (name: _: [
      "d ${dataDirOf name} - - -"
      "d /var/lib/tailscale-${name} - - -"
    ]) containers
  );

  containers = lib.mapAttrs (name: _: {
    autoStart = true;
    ephemeral = true;
    macvlans = [ interface ];

    bindMounts = {
      "/etc/ssh/ssh_host_ed25519_key".hostPath = config.sops.secrets."container/${name}/ssh-key".path;
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
        imports = [
          "${self}/modules/system/sops.nix"
          "${self}/modules/system/tailscale.nix"
        ];

        system = {
          inherit stateVersion;
        };

        networking = {
          inherit domain;
          useNetworkd = true;
          useHostResolvConf = false;
        };

        systemd.network = {
          enable = true;
          networks."10-mv-${interface}" = {
            matchConfig.Name = "mv-${interface}";
            networkConfig.DHCP = "yes";
            dhcpV4Config.ClientIdentifier = "mac";
          };
        };

        myConfig.sops = {
          enable = true;
          defaultSopsFile = ./${name}/secrets.yaml;
        };

        sops.secrets."tailscale-auth-key" = { };
        services.tailscale.interfaceName = "userspace-networking";
        myConfig.tailscale = {
          enable = true;
          ssh.enable = true;
        };
      };
  }) containers;
}
