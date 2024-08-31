{ config, ... }:
{
  sops.secrets = {
    "nextcloud/admin-password" = { };
    "nextcloud/gmail-password" = { };
    tailscale-auth-key = { };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tailscale-nextcloud - - -"
    "d /data/nextcloud - - -"
  ];

  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      "/run/secrets/nextcloud".isReadOnly = false;
      "/run/secrets/tailscale-auth-key" = { };
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
        };

        imports = [
          ./nextcloud.nix
          ./email-server.nix
          ./tailscale.nix
        ];
      };
  };
}
