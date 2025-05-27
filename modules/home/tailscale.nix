{ config, lib, ... }@moduleArgs:
{
  options.myConfig.tailscale.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.custom.services.tailscale.enable or false;
  };

  config = lib.mkIf config.myConfig.tailscale.enable {
    programs.ssh = {
      enable = true;
      matchBlocks.installer.extraOptions = {
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = "no";
      };
    };
  };
}
