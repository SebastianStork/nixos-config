{
  imports = [
    ../common.nix
    ./hardware.nix
    ./disko.nix
    ./containers
  ];

  system.stateVersion = "24.05";

  myConfig = {
    sops.enable = true;
    boot.loader.systemd-boot.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
      exitNode.enable = true;
    };
  };

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-eno1" = {
      matchConfig.Name = "eno1";
      networkConfig.DHCP = "yes";
    };
  };
}
