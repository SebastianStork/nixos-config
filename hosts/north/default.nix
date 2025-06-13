{ pkgs, ... }:
{
  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    sops.enable = true;
    boot = {
      loader.systemdBoot.enable = true;
      silent = true;
    };

    users.seb = {
      enable = true;
      zsh.enable = true;
      homeManager.enable = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    sound.enable = true;

    services = {
      resolved.enable = true;
      gc.enable = true;
      geoclue.enable = true;
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
}
