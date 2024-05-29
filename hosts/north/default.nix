{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "north";

  myConfig = {
    boot-loader = {
      systemd-boot.enable = true;
      silent = true;
    };

    dm.gdm.enable = true;
    de.hyprland.enable = true;

    sound.enable = true;
    vm.qemu.enable = true;
    vpn.lgs.enable = true;
    comma.enable = true;
    sops.enable = true;
    printing.enable = true;
    syncthing.enable = true;
    nix-helper = {
      enable = true;
      auto-gc.enable = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_6_8;

  programs.steam.enable = true;
}
