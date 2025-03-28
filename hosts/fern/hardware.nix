{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

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

  services = {
    fwupd.enable = true;
    fprintd.enable = true;
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };

    logind = {
      powerKey = "suspend-then-hibernate";
      lidSwitch = "suspend-then-hibernate";
    };
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
    HibernateOnACPower=yes
  '';
}
