_: {
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    services.tailscale = {
      enable = true;
      ssh.enable = true;
    };
  };
}
