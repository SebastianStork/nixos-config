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

    sops.enable = true;

    boot.loader.systemd-boot.enable = true;

    services = {
      gc = {
        enable = true;
        onlyCleanRoots = true;
      };

      tailscale.enable = true;

      nebula.node = {
        enable = true;
        address = "10.254.250.4";
        routableAddress = "167.235.73.246";
        isServer = true;
      };

      crowdsec = {
        enable = true;
        bouncers.firewall = true;
      };

    };

    web-services =
      let
        sstorkDomain = "sstork.dev";
        sproutedDomain = "sprouted.cloud";
      in
      {
        personal-blog = {
          enable = true;
          domain = sstorkDomain;
        };

        forgejo = {
          enable = true;
          domain = "git.${sstorkDomain}";
          doBackups = true;
        };

        outline = {
          enable = true;
          domain = "wiki.${sproutedDomain}";
          doBackups = true;
        };

        it-tools = {
          enable = true;
          domain = "tools.${sproutedDomain}";
        };

        privatebin = {
          enable = true;
          domain = "pastebin.${sproutedDomain}";
          branding.name = "SproutedBin";
        };

        alloy = {
          enable = true;
          domain = "alloy-${config.networking.hostName}.${config.custom.services.tailscale.domain}";
        };
      };
  };
}
