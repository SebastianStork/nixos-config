{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "24.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    sops.enable = true;

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
      resolved.enable = true;
      gc.enable = true;
      wlan.enable = true;
      bluetooth.enable = true;
      sound.enable = true;
      tailscale.enable = true;
      nebula.node = {
        enable = true;
        address = "10.254.250.3";
        isClient = true;
      };
      syncthing = {
        enable = true;
        deviceId = "Q4YPD3V-GXZPHSN-PT5X4PU-FBG4GX2-IASBX75-7NYMG75-4EJHBMZ-4WGDDAP";
      };
    };

    programs = {
      winboat.enable = true;
      wireshark.enable = true;
    };
  };

  programs.localsend.enable = true;
}
