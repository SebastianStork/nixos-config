{ config, ... }:
let
  myCfg = config.myConfig;
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

      caddyServe.nextcloud = {
        subdomain = "cloud";
        inherit (myCfg.nextcloud) port;
      };
    };

    nextcloud = {
      enable = true;
      backups.enable = true;
      inherit (myCfg.tailscale.caddyServe.nextcloud) subdomain;
    };
  };
}
