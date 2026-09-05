{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.grub.enable = true;

    networking = {
      overlay.address = "10.254.250.6";
      underlay = {
        interface = "enp2s0";
        cidr = "192.168.0.64/24";
        gateway = "192.168.0.1";
        trusted = true;
      };
    };

    services = {
      blocking-nameserver = {
        enable = true;
        gui.domain = "adguard.${config.networking.fqdn}";
      };
      recursive-nameserver = {
        enable = true;
        serveAuthoritatively = true;
      };

      syncthing = {
        enable = true;
        isServer = true;
        gui.domain = "syncthing.${config.networking.domain}";
        doBackups = true;
      };

      file-share.enable = true;

      prometheus.storageRetentionSize = "20GB";

      atuin-server = {
        enable = true;
        domain = "atuin.${config.networking.domain}";
      };

      garage = {
        enable = true;
        rootDomain = "s3.${config.networking.domain}";
      };

      s3-binary-cache = {
        enable = true;
        domain = "cache.${config.networking.domain}";
      };
    };

    web-services = {
      home-assistant = {
        enable = true;
        domain = "home-assistant.${config.networking.domain}";
        doBackups = true;
      };

      radicale = {
        enable = true;
        domain = "dav.${config.networking.domain}";
        doBackups = true;
      };

      actualbudget = {
        enable = true;
        domain = "budget.${config.networking.domain}";
        doBackups = true;
      };

      homebox = {
        enable = true;
        domain = "inventory.${config.networking.domain}";
        doBackups = true;
      };

      calibre-server = {
        enable = true;
        domain = "library.${config.networking.domain}";
      };

      karakeep = {
        enable = true;
        domain = "bookmarks.${config.networking.domain}";
      };

      grafana = {
        enable = true;
        domain = "grafana.${config.networking.domain}";
      };

      glance = {
        enable = true;
        domain = "home.${config.networking.domain}";
      };

      searxng = {
        enable = true;
        domain = "search.${config.networking.domain}";
      };

      scrutiny = {
        enable = true;
        domain = "scrutiny.${config.networking.domain}";
      };

      librespeed.frontend = {
        enable = true;
        domain = "speedtest.${config.networking.domain}";
      };
    };
  };
}
