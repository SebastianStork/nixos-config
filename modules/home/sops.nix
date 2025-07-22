{
  config,
  inputs,
  self,
  lib,
  ...
}@moduleArgs:
let
  cfg = config.custom.sops;

  absoluteSecretsPath = "${self}/" + cfg.secretsFile;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    agePublicKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    hostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = moduleArgs.osConfig.networking.hostName or "";
    };
    secretsFile = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "users/${config.home.username}/@${cfg.hostName}/secrets.json";
    };
    secrets = lib.mkOption {
      type = lib.types.anything;
      default = absoluteSecretsPath |> lib.readFile |> lib.strings.fromJSON;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      defaultSopsFile = absoluteSecretsPath;
    };
  };
}
