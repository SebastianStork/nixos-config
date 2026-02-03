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
  imports = [ inputs.sops.homeModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    hostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = moduleArgs.osConfig.networking.hostName or "";
    };
    agePublicKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default =
        "${self}/users/${config.home.username}/@${cfg.hostName}/keys/age.pub" |> lib.readFile |> lib.trim;
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = "${self}/users/${config.home.username}/@${cfg.hostName}/secrets.json";
    };
    secrets = lib.mkOption {
      type = lib.types.anything;
      default = cfg.secretsFile |> lib.readFile |> lib.strings.fromJSON;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      defaultSopsFile = cfg.secretsFile;
    };
  };
}
