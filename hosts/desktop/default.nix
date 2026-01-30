{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "23.11";
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

    networking = {
      overlay = {
        address = "10.254.250.1";
        role = "client";
      };
      underlay = {
        interface = "enp6s0";
        useDhcp = true;
      };
    };

    services = {
      auto-gc.enable = true;
      sound.enable = true;
      nebula.enable = true;
      sshd.enable = true;
      syncthing = {
        enable = true;
        deviceId = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";
      };
    };

    programs.steam.enable = true;
  };

  programs.localsend.enable = true;
}
