{ config, ... }:
{
  sops.secrets = {
    "nextcloud/admin-password" = { };
    "nextcloud/gmail-password" = { };
    tailscale-auth-key = { };
  };

  systemd.tmpfiles.rules = [
    "d /data/nextcloud - - -"
    "d /data/postgresql - - -"
  ];

  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      "/run/secrets/nextcloud".isReadOnly = false;
      "/run/secrets/tailscale-auth-key" = { };
      "/data/nextcloud".isReadOnly = false;
      "/data/postgresql".isReadOnly = false;
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
        };

        imports = [
          ./nextcloud.nix
          ./email-server.nix
          ./tailscale.nix
        ];
      };
  };
}
