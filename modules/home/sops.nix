{
  self,
  inputs,
  config,
  lib,
  ...
}@moduleArgs:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.myConfig.sops.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.sops.enable {
    sops = {
      age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      defaultSopsFile =
        let
          hostName = moduleArgs.osConfig.networking.hostName or "";
          hostDir = if hostName != "" then "/@" + hostName else "";
        in
        "${self}/users/${config.home.username}${hostDir}/secrets.yaml";
    };
  };
}
