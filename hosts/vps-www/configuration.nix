{ self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.systemd-boot.enable = true;

    networking = {
      overlay.address = "10.254.250.4";
      underlay = {
        interface = "enp1s0";
        cidr = "167.235.73.246/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services.public-nameserver = {
      enable = true;
      publicHostName = "ns2";
      zones = [
        "sprouted.cloud"
        "sstork.dev"
      ];
    };

    web-services = {
      personal-blog = {
        enable = true;
        domain = "sstork.dev";
      };

      forgejo = {
        enable = true;
        domain = "git.sstork.dev";
        doBackups = true;
      };

      outline = {
        enable = true;
        domain = "wiki.sprouted.cloud";
        doBackups = true;
      };

      it-tools = {
        enable = true;
        domain = "it-tools.sprouted.cloud";
      };

      networking-toolbox = {
        enable = true;
        domain = "net-tools.sprouted.cloud";
      };

      privatebin = {
        enable = true;
        domain = "pastebin.sprouted.cloud";
        branding.name = "SproutedBin";
      };

      screego = {
        enable = true;
        domain = "mirror.sprouted.cloud";
      };
    };
  };
}
