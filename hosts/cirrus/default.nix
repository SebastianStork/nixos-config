_: {
  system.stateVersion = "24.11";
  boot.loader.grub.enable = true;

  myConfig = {
    sops.enable = true;
    tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };
}
