{ config, ... }:
let
  myCfg = config.myConfig;
  caddyServe = myCfg.tailscale.caddyServe;
in
{
  system.stateVersion = "24.11";

  myConfig = {
    boot.loader.systemdBoot.enable = true;
    sops.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
      exitNode.enable = true;

      caddyServe = {
        nextcloud = {
          subdomain = "cloud";
          inherit (myCfg.nextcloud) port;
        };
        hedgedoc = {
          subdomain = "docs";
          inherit (myCfg.hedgedoc) port;
        };
      };
    };

    nextcloud = {
      enable = true;
      backups.enable = true;
      inherit (caddyServe.nextcloud) subdomain;
    };
    hedgedoc = {
      enable = true;
      backups.enable = true;
      inherit (caddyServe.hedgedoc) subdomain;
    };
  };
}
