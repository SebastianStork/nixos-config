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

  isoImage = {
    edition = lib.mkForce "seb-minimal";
    isoName = lib.mkForce "NixOS";
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    wireless.enable = false;
    networkmanager.enable = true;
  };

  environment.systemPackages = [ inputs.disko.packages.${pkgs.system}.default ];

  services.openssh.enable = lib.mkForce false;
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraUpFlags = [ "--ssh" ];

    # Ephemeral + not pre-approved
    authKeyFile = pkgs.writeText "tailscale-key-file" "tskey-auth-kaDD7BXvDE11CNTRL-9M4pUPEw4bEj7V4YzwFgaEE1MvzumcgM";
  };
}
