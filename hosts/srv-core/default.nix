{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom =
    let
      privateDomain = config.custom.networking.overlay.domain;
    in
    {
      boot.loader.grub.enable = true;

      networking = {
        overlay = {
          address = "10.254.250.6";
          isLighthouse = true;
        };
        underlay = {
          interface = "enp2s0";
          cidr = "192.168.0.64/24";
          gateway = "192.168.0.1";
        };
      };

      services = {
        nebula.advertise = {
          address = "130.83.103.62";
          port = 47033;
        };
        
        recursive-nameserver = {
          enable = true;
          blockAds = true;
        };
        private-nameserver.enable = true;

        syncthing = {
          enable = true;
          isServer = true;
          gui.domain = "syncthing.${privateDomain}";
          doBackups = true;
        };

        prometheus.storageRetentionSize = "20GB";
      };

      web-services = {
        atuin = {
          enable = true;
          domain = "atuin.${privateDomain}";
        };

        filebrowser = {
          enable = true;
          domain = "files.${privateDomain}";
          doBackups = true;
        };

        radicale = {
          enable = true;
          domain = "dav.${privateDomain}";
          doBackups = true;
        };

        actualbudget = {
          enable = true;
          domain = "budget.${privateDomain}";
          doBackups = true;
        };

        karakeep = {
          enable = true;
          domain = "bookmarks.${privateDomain}";
        };

        grafana = {
          enable = true;
          domain = "grafana.${privateDomain}";
        };

        gatus = {
          enable = true;
          domain = "status.${privateDomain}";
          generateDefaultEndpoints = true;
        };
      };
    };
}
