{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "inspiron";
  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myConfig = {
    boot = {
      loader.systemd-boot.enable = true;
      silent = true;
    };

    dm.gdm.enable = true;
    de.hyprland.enable = true;

    wlan.enable = true;
    bluetooth.enable = true;

    sound.enable = true;
    virtualisation.enable = true;
    flatpak.enable = true;
    comma.enable = true;
    sops.enable = true;
    printing.enable = true;
    syncthing.enable = true;
    nix-helper.enable = true;
    auto-gc.enable = true;
    geoclue.enable = true;
    tailscale.enable = true;
  };

  services.auto-cpufreq.enable = true;
}
