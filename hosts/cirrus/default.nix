{ config, ... }:
{
  system.stateVersion = "24.11";
  networking.domain = "sprouted.cloud";

  custom = {
    boot.loader.grub.enable = true;
    sops.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      hedgedoc = {
        enable = true;
        subdomain = "docs";
        backups.enable = true;
      };

      crowdsec = {
        enable = true;
        firewallBouncer.enable = true;
        sources = [
          "iptables"
          "caddy"
        ];
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."docs.${config.networking.domain}".extraConfig = ''
      reverse_proxy localhost:${toString config.custom.services.hedgedoc.port}
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
