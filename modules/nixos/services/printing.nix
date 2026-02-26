{ config, lib, ... }:
{
  options.custom.services.printing.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.printing.enable {
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
