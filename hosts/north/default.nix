{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./hardware
  ];

  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myConfig = {
    boot = {
      loader.systemd-boot.enable = true;
      silent = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    sound.enable = true;
    virtualisation.enable = true;
    comma.enable = true;
    sops.enable = true;
    printing.enable = true;
    syncthing.enable = true;
    auto-gc.enable = true;
    geoclue.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };

  programs.steam.enable = true;
}
