{ inputs, ... }:
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
  };

  zramSwap.enable = true;

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

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
    HibernateOnACPower=yes
  '';

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
      linkConfig.RequiredForOnline = "routable";
      networkConfig = {
        DHCP = "yes";
        IgnoreCarrierLoss = "3s";
      };
    };
  };
}
