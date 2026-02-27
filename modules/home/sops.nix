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
      type = self.lib.types.existingPath;
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

    assertions =
      (
        config.sops.secrets
        |> lib.attrNames
        |> lib.map (secretPath: {
          assertion = cfg.secrets |> lib.hasAttrByPath (secretPath |> lib.splitString "/");
          message = "Sops secret `${secretPath}` is used in a module but not defined in secrets.json";
        })
      )
      ++ (
        lib.removeAttrs cfg.secrets [ "sops" ]
        |> lib.mapAttrsToListRecursive (path: _: path |> lib.concatStringsSep "/")
        |> lib.map (secretPath: {
          assertion = config.sops.secrets |> lib.hasAttr secretPath;
          message = "Sops secret `${secretPath}` is defined in secrets.json but not used in any module";
        })
      );
  };
}
