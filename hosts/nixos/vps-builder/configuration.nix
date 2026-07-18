{ self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.systemd-boot.enable = true;

    networking = {
      overlay.address = "10.254.250.7";
      underlay = {
        interface = "enp1s0";
        cidr = "188.34.160.80/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services = {
      forgejo-runner = {
        enable = true;
        forgejoUrl = "https://codeberg.org";
        maxConcurrentJobs = 4;
      };
      gitlab-runner = {
        enable = true;
        gitlabUrl = "https://code.fbi.h-da.de";
        maxConcurrentJobs = 2;
      };
      renovate = {
        enable = true;
        forgejoUrl = "https://codeberg.org";
      };
    };

    web-services.librespeed.enable = true;
  };
}
