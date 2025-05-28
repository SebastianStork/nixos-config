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

      crowdsec = {
        enable = true;
        firewallBouncer.enable = true;
        sources = [
          "iptables"
          "caddy"
        ];
      };

      hedgedoc = {
        enable = true;
        domain = "docs.sprouted.cloud";
        backups.enable = true;
      };
      forgejo = {
        enable = true;
        domain = "git.sstork.dev";
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      ${config.custom.services.hedgedoc.domain}.extraConfig = ''
        reverse_proxy localhost:${toString config.custom.services.hedgedoc.port}
      '';
      ${config.custom.services.forgejo.domain}.extraConfig = ''
        reverse_proxy localhost:${toString config.custom.services.forgejo.port}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
