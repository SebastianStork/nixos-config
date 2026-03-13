{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.sops;
in
{
  imports = [ inputs.sops.nixosModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    agePublicKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "${self}/hosts/${config.networking.hostName}/keys/age.pub" |> lib.readFile |> lib.trim;
    };
    secretsFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/hosts/${config.networking.hostName}/secrets.json";
    };
    secretsData = lib.mkOption {
      type = lib.types.attrs;
      default = cfg.secretsFile |> lib.readFile |> lib.strings.fromJSON;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [
        "${lib.optionalString config.custom.persistence.enable "/persist"}/etc/ssh/ssh_host_ed25519_key"
      ];
      defaultSopsFile = cfg.secretsFile;
    };

    assertions =
      (
        config.sops.secrets
        |> lib.attrNames
        |> lib.map (secretPath: {
          assertion = cfg.secretsData |> lib.hasAttrByPath (secretPath |> lib.splitString "/");
          message = "Sops secret `${secretPath}` is used in a module but not defined in secrets.json";
        })
      )
      ++ (
        lib.removeAttrs cfg.secretsData [ "sops" ]
        |> lib.mapAttrsToListRecursive (path: _: path |> lib.concatStringsSep "/")
        |> lib.map (secretPath: {
          assertion = config.sops.secrets |> lib.hasAttr secretPath;
          message = "Sops secret `${secretPath}` is defined in secrets.json but not used in any module";
        })
      );
  };
}
