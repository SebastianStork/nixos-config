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
        cidr = "188.34.160.80/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services = {
      public-nameserver = {
        enable = true;
        publicHostName = "ns2";
        zones = [
          "sprouted.cloud"
          "web.sstork.dev"
        ];
      };

      forgejo-runner = {
        enable = true;
        forgejoUrl = "https://codeberg.org";
        maxConcurrentJobs = 4;
      };

      renovate = {
        enable = true;
        forgejoUrl = "https://codeberg.org";
      };

      caddy.virtualHosts."git.sstork.dev".extraConfig = ''
        redir https://git.web.sstork.dev{uri} permanent
      '';
    };

    web-services = {
      forgejo = {
        enable = true;
        domain = "git.web.sstork.dev";
        doBackups = true;
      };

      outline = {
        enable = true;
        domain = "wiki.sprouted.cloud";
        doBackups = true;
      };

      outline-to-anki = {
        enable = true;
        domain = "anki-decks.sprouted.cloud";
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
    };
  };
}
