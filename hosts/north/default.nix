{ pkgs, ... }:
{
  imports = [
    ../shared.nix
    ./hardware.nix
    ./disko.nix
  ];

  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myConfig = {
    boot = {
      loader.systemdBoot.enable = true;
      silent = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    sound.enable = true;
    virtualisation.enable = true;
    sops.enable = true;
    garbageCollection.enable = true;
    geoclue.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
    };
    syncthing.enable = true;

    steam.enable = true;
  };
}
