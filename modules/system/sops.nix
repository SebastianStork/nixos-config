{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.myConfig.sops.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.sops.enable {
    sops = {
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      defaultSopsFile = ../../hosts/dell-laptop/secrets.yaml;
    };
  };
}
