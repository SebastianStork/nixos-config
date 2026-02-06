{
  config,
  osConfig,
  inputs,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.sops;
in
{
  imports = [ inputs.sops.homeModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    agePublicKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default =
        "${self}/users/${config.home.username}/@${osConfig.networking.hostName}/keys/age.pub"
        |> lib.readFile
        |> lib.trim;
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = "${self}/users/${config.home.username}/@${osConfig.networking.hostName}/secrets.json";
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
