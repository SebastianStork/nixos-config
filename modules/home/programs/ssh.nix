{
  config,
  osConfig,
  self,
  lib,
  ...
}:
{
  options.custom.programs.ssh = {
    enable = lib.mkEnableOption "";
    publicKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/users/${config.home.username}/@${osConfig.networking.hostName}/keys/ssh.pub";
    };
  };

  config = lib.mkIf config.custom.programs.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}
