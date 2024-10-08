{
  imports = [
    ../common.nix
    ./hardware.nix
    ./disko.nix

    ./containers/docker
    ./containers/nspawn
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
}
