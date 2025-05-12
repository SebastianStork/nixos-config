_: {
  system.stateVersion = "24.11";

  myConfig = {
    boot.loader.grub.enable = true;
    sops.enable = true;

    tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };
}
