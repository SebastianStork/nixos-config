{
  imports = [
    ../shared.nix
    ./hardware.nix
    ./disko.nix
  ];

  system.stateVersion = "24.11";

  myConfig = {
    boot.loader.systemdBoot.enable = true;
    sops.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
      exitNode.enable = true;
    };
  };
}
