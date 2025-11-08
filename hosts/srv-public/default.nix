{ config, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "25.05";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom = {
    impermanence.enable = true;

    sops = {
      enable = true;
      agePublicKey = "age1tfgn62qe9264yzsw5svdppz57e3dhlzfcf043ecpg82mgny88gwsdxg9vz";
    };

    boot.loader.grub.enable = true;

    services =
      let
        sstorkDomain = "sstork.dev";
        sproutedDomain = "sprouted.cloud";
      in
      {
        tailscale = {
          enable = true;
          ssh.enable = true;
        };

        crowdsec = {
          enable = true;
          sources = {
            iptables = true;
            sshd = true;
            caddy = true;
          };
          bouncers.firewall = true;
        };

        personal-blog = {
          enable = true;
          domain = sstorkDomain;
        };

        forgejo = {
          enable = true;
          domain = "git.${sstorkDomain}";
          doBackups = true;
          ssh.enable = true;
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

        stirling-pdf = {
          enable = true;
          domain = "pdf.${sproutedDomain}";
          branding = {
            name = "Sprouted PDF";
            description = "Sprouted's one-stop-shop for all your PDF needs.";
          };
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
