{
  config,
  osConfig,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.programs.ssh;

  mkRoleOptions = role: {
    enable = lib.mkEnableOption "";
    publicKeyFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/users/${config.home.username}/@${osConfig.networking.hostName}/keys/ssh-${role}.pub";
    };
  };
in
{
  options.custom.programs.ssh = {
    login = mkRoleOptions "login";
    deploy = mkRoleOptions "deploy";
  };

  config = lib.mkMerge [
    {
      programs.ssh = lib.mkIf (cfg.login.enable || cfg.deploy.enable) {
        enable = true;
        enableDefaultConfig = false;
      };
    }
    (lib.mkIf cfg.deploy.enable {
      services.ssh-agent.enable = true;

      programs.ssh.settings."Match user deploy" = {
        addKeysToAgent = "15m";
        identityFile = "~/.ssh/id_ed25519_deploy";
        identitiesOnly = true;
      };
    })
  ];
}
