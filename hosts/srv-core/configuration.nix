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
      };
    };

    services = {
      recursive-nameserver = {
        enable = true;
        blockAds = true;
      };
      private-nameserver.enable = true;

      syncthing = {
        enable = true;
        isServer = true;
        gui.domain = "syncthing.${config.custom.networking.overlay.domain}";
        doBackups = true;
      };

      prometheus.storageRetentionSize = "20GB";
    };

    web-services = {
      atuin = {
        enable = true;
        domain = "atuin.${config.custom.networking.overlay.domain}";
      };

      filebrowser = {
        enable = true;
        domain = "files.${config.custom.networking.overlay.domain}";
        doBackups = true;
      };

      radicale = {
        enable = true;
        domain = "dav.${config.custom.networking.overlay.domain}";
        doBackups = true;
      };

      actualbudget = {
        enable = true;
        domain = "budget.${config.custom.networking.overlay.domain}";
        doBackups = true;
      };

      karakeep = {
        enable = true;
        domain = "bookmarks.${config.custom.networking.overlay.domain}";
      };

      grafana = {
        enable = true;
        domain = "grafana.${config.custom.networking.overlay.domain}";
      };

      glance = {
        enable = true;
        domain = "home.${config.custom.networking.overlay.domain}";
      };

      searxng = {
        enable = true;
        domain = "search.${config.custom.networking.overlay.domain}";
      };
    };
  };
}
