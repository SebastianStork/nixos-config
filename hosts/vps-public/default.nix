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
      agePublicKey = "age1j47wr83tg4t8sdjcyarwvvrt8qzjrgw2fa2e4nufffdev89t8prsu7lxnh";
    };

    boot.loader.systemd-boot.enable = true;

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
