{ config, ... }:
{
  sops.secrets.seb-password.neededForUsers = true;

  users.users.seb = {
    isNormalUser = true;
    description = "Sebastian Stork";
    hashedPasswordFile = config.sops.secrets.seb-password.path;
    extraGroups = [
      "wheel"
      "libvirtd"
    ];
  };
}
