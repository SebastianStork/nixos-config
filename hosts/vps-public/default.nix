{ config, self, ... }:
{
  imports = [ self.nixosModules.profile-server ];

  system.stateVersion = "25.11";

  custom =
    let
      sproutedDomain = "sprouted.cloud";
    in
    {
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

      services.caddy.virtualHosts."dav.${sproutedDomain}" = {
        inherit (config.custom.web-services.radicale) port;
        extraConfig = ''
          respond /.web/ "Access denied" 403 { close }
        '';
      };

      web-services =
        let
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
            domain = "dav.${config.custom.networking.overlay.domain}";
            doBackups = true;
          };
        };
    };
}
