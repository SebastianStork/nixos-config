{config, ...}: {
  imports = [../default.nix];

  sops.secrets."password/seb".neededForUsers = true;

  users.users.seb = {
    isNormalUser = true;
    description = "Sebastian Stork";
    hashedPasswordFile = config.sops.secrets."password/seb".path;
    extraGroups = ["wheel" "networkmanager" "libvirtd"];
  };

  home-manager.users.seb = import ./home.nix;
}
