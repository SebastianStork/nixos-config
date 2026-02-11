{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom =
    let
      privateDomain = config.custom.networking.overlay.domain;
    in
    {
      boot.loader.systemd-boot.enable = true;

      networking = {
        overlay = {
          address = "10.254.250.2";
          isLighthouse = true;
        };
        underlay = {
          interface = "enp1s0";
          cidr = "49.13.231.235/32";
          isPublic = true;
          gateway = "172.31.1.1";
        };
      };

      services = {
        dns.enable = true;

        syncthing = {
          enable = true;
          isServer = true;
          gui.domain = "syncthing.${privateDomain}";
          doBackups = true;
        };

        atuin = {
          enable = true;
          domain = "atuin.${privateDomain}";
        };
      };

      web-services = {
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
      };
    };
}
