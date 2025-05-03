{ modulesPath, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  zramSwap.enable = true;

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-ens3" = {
      matchConfig.Name = "ens3";
      address = [
        "152.53.85.193/22"
        "2a0a:4cc0:c0:23bd::1/64"
      ];
      routes = [
        { Gateway = "152.53.84.1"; }
        { Gateway = "fe80::1"; }
      ];
      dns = [
        "46.38.225.230"
        "46.38.252.230"
        "2a03:4000:0:1::e1e6"
        "2a03:4000:8000::fce6"
      ];
      linkConfig.RequiredForOnline = "routable";
    };
  };
  services.resolved.enable = true;
}
