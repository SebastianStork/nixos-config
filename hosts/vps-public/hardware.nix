{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  zramSwap.enable = true;

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-enp1s0" = {
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "routable";
      networkConfig.DHCP = "no";
      address = [
        "167.235.73.246/32"
        "2a01:4f8:c0c:3baf::1/64"
      ];
      routes = [
        {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        }
        { Gateway = "fe80::1"; }
      ];
      dns = [
        "1.1.1.1"
        "8.8.8.8"
        "2606:4700:4700::1111"
        "2001:4860:4860::8888"
      ];
    };
  };
}
