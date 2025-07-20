{
  config,
  inputs,
  self,
  lib,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.custom.sops.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.sops.enable {
    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = "${self}/hosts/${config.networking.hostName}/secrets.json";
    };
  };
}
