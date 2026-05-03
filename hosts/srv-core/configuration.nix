{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  system.activationScripts.fail = "exit 1";

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
      blocking-nameserver = {
        enable = true;
        gui.domain = "adguard.${config.custom.networking.overlay.fqdn}";
      };
      recursive-nameserver.enable = true;
      private-nameserver.enable = true;

      syncthing = {
        enable = true;
        isServer = true;
        gui.domain = "syncthing.${config.custom.networking.overlay.domain}";
        doBackups = true;
      };

      file-share.enable = true;

      prometheus.storageRetentionSize = "20GB";
    };

    web-services = {
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

      atuin = {
        enable = true;
        domain = "atuin.${config.custom.networking.overlay.domain}";
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

      scrutiny = {
        enable = true;
        domain = "scrutiny.${config.custom.networking.overlay.domain}";
      };

      garage = {
        enable = true;
        rootDomain = "s3.${config.custom.networking.overlay.domain}";
      };

      s3-binary-cache = {
        enable = true;
        domain = "cache.${config.custom.networking.overlay.domain}";
      };

      librespeed = {
        enable = true;
        frontend = {
          enable = true;
          domain = "speedtest.${config.custom.networking.overlay.domain}";
        };
      };
    };
  };
}
