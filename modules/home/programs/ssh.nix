{
  config,
  self,
  lib,
  ...
}@moduleArgs:
let
  cfg = config.custom.programs.ssh;
in
{
  options.custom.programs.ssh = {
    enable = lib.mkEnableOption "";
    hostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = moduleArgs.osConfig.networking.hostName or "";
    };
    publicKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/users/${config.home.username}/@${cfg.hostName}/keys/ssh.pub";
    };
  };

  config = lib.mkIf config.custom.programs.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}
