{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "north";
  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackages_6_8;

  myConfig = {
    boot.loader.systemd-boot.enable = true;
    boot.silent = true;

    dm.gdm.enable = true;
    de.hyprland.enable = true;

    sound.enable = true;
    virtualisation.enable = true;
    comma.enable = true;
    sops.enable = true;
    printing.enable = true;
    syncthing.enable = true;
    nix-helper.enable = true;
    auto-gc.enable = true;
    geoclue.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };

  programs.steam.enable = true;
}
