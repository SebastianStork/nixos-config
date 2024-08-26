{ config, lib, ... }:
{
  options.myConfig.nextcloud.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nextcloud.enable {
    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
