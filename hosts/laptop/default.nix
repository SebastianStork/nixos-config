{ pkgs, ... }:
{
  system.stateVersion = "24.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    sops = {
      enable = true;
      agePublicKey = "age1sywwrwse76x8yskrsfpwk38fu2cmyx5s9qkf2pgc68cta0vj9psql7dp6e";
    };

    boot = {
      loader.systemd-boot.enable = true;
      silent = true;
    };

    dm.tuigreet = {
      enable = true;
      autoLogin = true;
    };
    de.hyprland.enable = true;

    services = {
      gc.enable = true;
      wlan.enable = true;
      bluetooth.enable = true;
      sound.enable = true;
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
