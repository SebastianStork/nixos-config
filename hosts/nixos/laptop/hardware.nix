{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  boot = {
    kernelModules = [ "kvm-amd" ];
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
    kernelParams = [
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
    ];
  };

  security.pam.services.login.fprintAuth = false;

  services = {
    fwupd.enable = true;
    fprintd.enable = true; # fwupdmgr refresh && fwupdmgr update
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };

    logind.settings.Login = {
      HandlePowerKey = "suspend-then-hibernate";
      HandleLidSwitch = "suspend-then-hibernate";
    };
  };

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "2h";
    HibernateOnACPower = true;
  };

  environment.etc."systemd/system-sleep/hibernate-memory-reclaim".source =
    pkgs.writeShellScript "hibernate-memory-reclaim" ''
      if [[ "$1:$2" == "pre:hibernate" || "$1:$2" == "pre:suspend-then-hibernate" ]]; then
        ${pkgs.coreutils}/bin/sync
        echo 0 > /sys/power/image_size
        echo 3 > /proc/sys/vm/drop_caches
        echo 1 > /proc/sys/vm/compact_memory
      fi
    '';
}
