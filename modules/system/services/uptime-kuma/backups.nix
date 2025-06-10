{ config, lib, ... }:
{
  options.custom.services.uptimeKuma.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.uptimeKuma.backups.enable {
    custom.services.resticBackups.uptime-kuma = {
      healthchecks.enable = false;
      dependentService = "uptime-kuma.service";
      extraConfig.paths = [ "/var/lib/private/uptime-kuma" ];
    };
  };
}
