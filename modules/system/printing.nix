{ config, lib, ... }:
{
  options.myConfig.printing.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.printing.enable {
    services = {
      printing.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
  };
}
