{ config, ... }:
{
  sops.secrets = {
    "nextcloud/admin-password" = { };
    "nextcloud/gmail-password" = { };
    tailscale-auth-key = { };
  };

  systemd.tmpfiles.rules = [
    "d /data/nextcloud - - -"
    "d /var/lib/tailscale-nextcloud - - -"
  ];

  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    macvlans = [ "eno1" ];

    bindMounts = {
      # Secrets
      "/run/secrets/nextcloud".isReadOnly = false;
      "/run/secrets/tailscale-auth-key" = { };

      # State
      "/data/nextcloud".isReadOnly = false;
      "/var/lib/tailscale" = {
        hostPath = "/var/lib/tailscale-nextcloud";
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
            address = [ "192.168.2.254/24" ];
            networkConfig.DHCP = "yes";
            dhcpV4Config.ClientIdentifier = "mac";
          };
        };

        imports = [
          ./nextcloud.nix
          ./email-server.nix
          ./tailscale.nix
        ];
      };
  };
}