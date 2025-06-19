{ pkgs, ... }:
{
  system.stateVersion = "24.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    sops.enable = true;
    boot = {
      loader.systemdBoot.enable = true;
      silent = true;
    };

    users.seb = {
      enable = true;
      zsh.enable = true;
      homeManager.enable = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    wifi.enable = true;
    bluetooth.enable = true;
    sound.enable = true;

    services = {
      resolved.enable = true;
      gc.enable = true;
      geoclue.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };
      syncthing = {
        enable = true;
        deviceId = "Q4YPD3V-GXZPHSN-PT5X4PU-FBG4GX2-IASBX75-7NYMG75-4EJHBMZ-4WGDDAP";
      };
    };
  };
}
