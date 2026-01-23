{ config, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "25.11";

  custom =
    let
      sproutedDomain = "sprouted.cloud";
    in
    {
      persistence.enable = true;

      sops.enable = true;

      boot.loader.systemd-boot.enable = true;

      networking = {
        overlay.address = "10.254.250.4";
        underlay = {
          interface = "enp1s0";
          address = "167.235.73.246";
          isPublic = true;
        };
        isServer = true;
      };

      services = {
        auto-gc = {
          enable = true;
          onlyCleanRoots = true;
        };

        nebula.enable = true;
        sshd.enable = true;

        caddy.virtualHosts."dav.${sproutedDomain}" = {
          inherit (config.custom.web-services.radicale) port;
          extraConfig = ''
            respond /.web/ "Access denied" 403 { close }
          '';
        };
      };

      web-services =
        let
          privateDomain = config.custom.networking.overlay.domain;
          sstorkDomain = "sstork.dev";
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
            domain = "it-tools.${sproutedDomain}";
          };

          networking-toolbox = {
            enable = true;
            domain = "net-tools.${sproutedDomain}";
          };

          privatebin = {
            enable = true;
            domain = "pastebin.${sproutedDomain}";
            branding.name = "SproutedBin";
          };

          screego = {
            enable = true;
            domain = "mirror.${sproutedDomain}";
          };

          radicale = {
            enable = true;
            domain = "dav.${privateDomain}";
            doBackups = true;
          };

          alloy = {
            enable = true;
            domain = "alloy.${config.networking.hostName}.${privateDomain}";
          };
        };
    };
}
