{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  cfg = config.myConfig.sops;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.myConfig.sops = {
    enable = lib.mkEnableOption "";
    defaultSopsFile = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${config.networking.hostName}/secrets.yaml";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      inherit (cfg) defaultSopsFile;
    };
  };
}
