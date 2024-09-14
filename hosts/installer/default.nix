{
  modulesPath,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../common.nix
  ];

  isoImage = {
    edition = lib.mkForce "seb-minimal";
    isoName = lib.mkForce "NixOS.iso";
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
    authKeyFile = pkgs.writeText "tailscale-key-file" "tskey-auth-kpQTjZCfoq11CNTRL-5iz9m4oKXxhwiREVgJbAxhC86fzBxVbFg";
  };
}
