{
  modulesPath,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../common.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    wireless.enable = false;
    networkmanager.enable = true;
  };

  environment.systemPackages = [ inputs.disko.packages.${pkgs.system}.default ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBUORYC3AvTPQmtUEApTa9DvHoJy4mjuQy8abSjCcDd seb@north"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtHQDVdFkshpLANxS07Hy+yKoUp8YAPd+WaojJkFVZq seb@inspiron"
  ];

  installer.cloneConfig = false;
  isoImage = {
    edition = lib.mkForce "seb-minimal";
    isoName = lib.mkForce "NixOS";
  };
}
