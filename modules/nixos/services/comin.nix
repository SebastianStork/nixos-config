{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.services.comin;
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  options.custom.services.comin = {
    enable = lib.mkEnableOption "";
    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 4243;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."git/push-token" = { };
    systemd.services.comin.serviceConfig.LoadCredential = "git-push-token:${
      config.sops.secrets."git/push-token".path
    }";

    services.comin = {
      enable = true;
      remotes = lib.singleton {
        name = "origin";
        url = "https://github.com/SebastianStork/nixos-config.git";
        branches.main.name = "deploy";
      };
      exporter = {
        listen_address = "127.0.0.1";
        port = cfg.metricsPort;
      };
    };
  };
}
