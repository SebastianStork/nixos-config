{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.renovate;
in
{
  options.custom.services.renovate = {
    enable = lib.mkEnableOption "";
    forgejoUrl = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.renovate = {
        isSystemUser = true;
        group = "renovate";
      };
      groups.renovate = { };
    };

    sops.secrets."renovate/token".owner = config.users.users.renovate.name;

    services.renovate = {
      enable = true;
      schedule = "*:0/15";
      credentials.RENOVATE_TOKEN = config.sops.secrets."renovate/token".path;
      runtimePackages = [ pkgs.nix ];
      settings = {
        platform = "forgejo";
        endpoint = cfg.forgejoUrl;
        binarySource = "global";
        autodiscover = true;
        autodiscoverFilter = [ "SebastianStork/*" ];
        onboarding = false;
      };
    };

    systemd.services.renovate.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.renovate.name;
      Group = config.users.groups.renovate.name;
      ProtectSystem = "strict";
      PrivateTmp = true;
      RemoveIPC = true;
    };

    nix.settings.allowed-users = [ config.users.users.renovate.name ];

    custom.persistence.directories = [ "/var/lib/renovate" ];
  };
}
