{ config, lib, ... }:
let
  cfg = config.myConfig.tailscale;
in
{
  options.myConfig.tailscale = {
    enable = lib.mkEnableOption "";
    ssh.enable = lib.mkEnableOption "";
    exitNode.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale-auth-key.restartUnits = [ "tailscaled-autoconnect.service" ];

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      openFirewall = true;
      useRoutingFeatures = if cfg.exitNode.enable then "server" else "client";
      extraUpFlags = [ "--reset=true" ];
      extraSetFlags = [
        "--ssh=${lib.boolToString cfg.ssh.enable}"
        "--advertise-exit-node=${lib.boolToString cfg.exitNode.enable}"
      ];
    };
  };
}
