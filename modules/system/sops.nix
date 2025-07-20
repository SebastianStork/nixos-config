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
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.custom.sops = {
    enable = lib.mkEnableOption "";
    defaultSopsFile = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${config.networking.hostName}/secrets.json";
    };
    secrets = lib.mkOption {
      type = lib.types.anything;
      default = cfg.defaultSopsFile |> builtins.readFile |> builtins.fromJSON;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      inherit (cfg) defaultSopsFile;
    };
  };
}
