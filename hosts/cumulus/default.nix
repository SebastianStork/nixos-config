{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    users.seb.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      gatus = {
        enable = true;
        domain = "status.${config.custom.services.tailscale.domain}";
      };
      ntfy = {
        enable = true;
        domain = "alerts.${config.custom.services.tailscale.domain}";
      };

      caddy.virtualHosts = {
        gatus = {
          inherit (config.custom.services.gatus) domain port;
        };
        ntfy = {
          inherit (config.custom.services.ntfy) domain port;
        };
      };
    };
  };
}
