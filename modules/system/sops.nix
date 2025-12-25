{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.sops;

  absoluteSecretsPath = "${self}/${cfg.secretsFile}";
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
      type = lib.types.nonEmptyStr;
      default = "hosts/${config.networking.hostName}/secrets.json";
    };
    secrets = lib.mkOption {
      type = lib.types.anything;
      default = absoluteSecretsPath |> lib.readFile |> lib.strings.fromJSON;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [
        "${lib.optionalString config.custom.persistence.enable "/persist"}/etc/ssh/ssh_host_ed25519_key"
      ];
      defaultSopsFile = absoluteSecretsPath;
    };
  };
}
