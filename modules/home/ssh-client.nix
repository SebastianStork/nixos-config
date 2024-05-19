{ config, lib, ... }:
{
  options.myConfig.ssh-client.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.ssh-client.enable {
    programs.ssh = {
      enable = true;

      addKeysToAgent = "confirm";
    };

    services.ssh-agent.enable = true;
  };
}
