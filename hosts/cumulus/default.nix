{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      uptimeKuma = {
        enable = true;
        domain = "uptime.${config.custom.services.tailscale.domain}";
      };
      ntfy = {
        enable = true;
        domain = "notify.${config.custom.services.tailscale.domain}";
      };

      caddy.virtualHosts = {
        uptimeKuma = {
          inherit (config.custom.services.uptimeKuma) domain port;
        };
        ntfy = {
          inherit (config.custom.services.ntfy) domain port;
        };
      };
    };
  };
}
