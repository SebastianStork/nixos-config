{
  imports = [
    ./containers/docker
    ./containers/nspawn
  ];

  system.stateVersion = "24.05";

  myConfig = {
    sops.enable = true;
    boot.loader.systemdBoot.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
      exitNode.enable = true;
    };
  };
}
