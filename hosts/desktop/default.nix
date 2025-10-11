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
    sops = {
      enable = true;
      agePublicKey = "age18x6herevmcuhcmeh47ll6p9ck9zk4ga6gfxwlc8yl49rwjxm7qusylwfgc";
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
      sound.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };
      syncthing = {
        enable = true;
        deviceId = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";
      };
    };

    programs.steam.enable = true;
  };

  services.foldingathome = {
    enable = true;
    user = "SebastianStork";
    daemonNiceLevel = 19;
  };
}
