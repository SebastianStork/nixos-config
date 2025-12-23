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

  custom = {
    persistence.enable = true;

    sops = {
      enable = true;
      agePublicKey = "age1e9a0jj0t5mwep4zgaplsuw57750g0sv5uujvx56ad0te0rle0e0q6ywu69";
    };

    boot.loader.systemd-boot.enable = true;

    services =
      let
        tailscaleDomain = config.custom.services.tailscale.domain;
      in
      {
        tailscale = {
          enable = true;
          ssh.enable = true;
          exitNode.enable = true;
        };
        nebula.node = {
          enable = true;
          address = "10.254.250.2";
          isLighthouse = true;
          routableAddress = "49.13.231.235";
        };

        syncthing = {
          enable = true;
          isServer = true;
          doBackups = true;
          deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
          gui.domain = "syncthing.${tailscaleDomain}";
        };

        filebrowser = {
          enable = true;
          domain = "files.${tailscaleDomain}";
          doBackups = true;
        };

        radicale = {
          enable = true;
          domain = "calendar.${tailscaleDomain}";
          doBackups = true;
        };

        memos = {
          enable = true;
          domain = "memos.${tailscaleDomain}";
          doBackups = true;
        };

        actualbudget = {
          enable = true;
          domain = "budget.${tailscaleDomain}";
          doBackups = true;
        };

        freshrss = {
          enable = true;
          domain = "rss.${tailscaleDomain}";
          doBackups = true;
        };

        alloy = {
          enable = true;
          domain = "alloy-${config.networking.hostName}.${tailscaleDomain}";
        };
      };
  };
}
