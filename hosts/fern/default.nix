{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
    ./disko.nix
  ];

  system.stateVersion = "24.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myConfig = {
    boot = {
      loader.systemd-boot.enable = true;
      silent = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    wlan.enable = true;
    bluetooth.enable = true;

    sound.enable = true;
    virtualisation.enable = true;
    sops.enable = true;
    auto-gc.enable = true;
    geoclue.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };
}
