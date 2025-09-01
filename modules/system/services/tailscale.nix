{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.tailscale;
in
{
  options.custom.services.tailscale = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "stork-atlas.ts.net";
    };
    ssh.enable = lib.mkEnableOption "";
    exitNode.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta.ports.udp.list = lib.mkIf config.services.tailscale.openFirewall [
      config.services.tailscale.port
    ];

    sops.secrets."tailscale/auth-key" = { };

    services.tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;

      authKeyFile = config.sops.secrets."tailscale/auth-key".path;
      openFirewall = true;
      useRoutingFeatures = if cfg.exitNode.enable then "server" else "client";

      extraUpFlags = [ "--reset=true" ];
      extraSetFlags = [
        "--ssh=${lib.boolToString cfg.ssh.enable}"
        "--advertise-exit-node=${lib.boolToString cfg.exitNode.enable}"
      ];
    };

    systemd.services.tailscaled-set.after = [ "tailscaled-autoconnect.service" ];
  };
}
