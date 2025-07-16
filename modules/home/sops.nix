{
  config,
  inputs,
  self,
  lib,
  ...
}@moduleArgs:
let
  cfg = config.custom.sops;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    hostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = moduleArgs.osConfig.networking.hostName or "";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      defaultSopsFile = "${self}/users/${config.home.username}/${cfg.hostName}/secrets.yaml";
    };
  };
}
