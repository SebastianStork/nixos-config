{ config, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "25.11";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom =
    let
      privateDomain = config.custom.networking.overlay.domain;
    in
    {
      persistence.enable = true;

      sops.enable = true;

      boot.loader.systemd-boot.enable = true;

      networking = {
        overlay.address = "10.254.250.2";
        underlay = {
          interface = "enp1s0";
          address = "49.13.231.235";
          isPublic = true;
        };
        isLighthouse = true;
        isServer = true;
      };

      services = {
        gc = {
          enable = true;
          onlyCleanRoots = true;
        };

        nebula.enable = true;
        sshd.enable = true;
        dns.enable = true;

        syncthing = {
          enable = true;
          isServer = true;
          doBackups = true;
          deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
          gui.domain = "syncthing.${privateDomain}";
        };
      };

      web-services = {
        filebrowser = {
          enable = true;
          domain = "files.${privateDomain}";
          doBackups = true;
        };

        memos = {
          enable = true;
          domain = "memos.${privateDomain}";
          doBackups = true;
        };

        actualbudget = {
          enable = true;
          domain = "budget.${privateDomain}";
          doBackups = true;
        };

        freshrss = {
          enable = true;
          domain = "rss.${privateDomain}";
          doBackups = true;
        };

        alloy = {
          enable = true;
          domain = "alloy.${config.networking.hostName}.${privateDomain}";
        };
      };
    };
}
