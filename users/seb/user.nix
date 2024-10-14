{ config, pkgs, ... }:
{
  sops.secrets."seb-password".neededForUsers = true;

  users.users.seb = {
    isNormalUser = true;
    description = "Sebastian Stork";
    hashedPasswordFile = config.sops.secrets."seb-password".path;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "libvirtd"
      "vboxusers"
    ];
  };
}
