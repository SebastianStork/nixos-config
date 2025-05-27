{ pkgs, ... }:
{
  system.stateVersion = "23.11";
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_6_14.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
          sha256 = "sha256-IYF/GZjiIw+B9+T2Bfpv3LBA4U+ifZnCfdsWznSXl6k=";
        };
        version = "6.14.6";
        modDirVersion = "6.14.6";
      };
    }
  );

  custom = {
    sops.enable = true;
    boot = {
      loader.systemdBoot.enable = true;
      silent = true;
    };

    dm.tuigreet.enable = true;
    de.hyprland.enable = true;

    virtualisation.enable = true;

    services = {
      sound.enable = true;
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
