{ config, ... }:
{
  sops.secrets = {
    "paperless-admin-password" = { };
    tailscale-auth-key = { };
  };

  systemd.tmpfiles.rules = [
    "d /data/paperless - - -"
    "d /var/lib/tailscale-paperless - - -"
  ];

  containers.paperless = {
    autoStart = true;
    ephemeral = true;
    macvlans = [ "eno1" ];

    bindMounts = {
      # Secrets
      "/run/secrets/paperless-admin-password" = { };
      "/run/secrets/tailscale-auth-key" = { };

      # State
      "/data/paperless".isReadOnly = false;
      "/var/lib/tailscale" = {
        hostPath = "/var/lib/tailscale-paperless";
        isReadOnly = false;
      };
    };

    specialArgs = {
      inherit (config.networking) domain;
    };
    config =
      { domain, ... }:
      {
        system.stateVersion = "24.05";

        networking = {
          inherit domain;
          useNetworkd = true;
          useHostResolvConf = false;
        };
        systemd.network = {
          enable = true;
          networks."40-mv-eno1" = {
            matchConfig.Name = "mv-eno1";
            address = [ "192.168.2.253/24" ];
            networkConfig.DHCP = "yes";
            dhcpV4Config.ClientIdentifier = "mac";
          };
        };

        imports = [
          ./paperless.nix
          ./tailscale.nix
        ];
      };
  };
}
