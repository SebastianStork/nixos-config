{ config, lib, ... }:
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
    meta.ports.udp = lib.mkIf config.services.tailscale.openFirewall [
      config.services.tailscale.port
    ];

    sops.secrets."tailscale/auth-key".restartUnits = [ "tailscaled-autoconnect.service" ];

    services.tailscale = {
      enable = true;
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

    custom.persistence.directories = [ "/var/lib/tailscale" ];

    # Disable search domain when nebula is in use
    systemd.network.networks."50-tailscale" = lib.mkIf config.custom.services.nebula.node.enable {
      matchConfig.Name = config.services.tailscale.interfaceName;
      linkConfig.Unmanaged = lib.mkForce false;
      dns = [ "100.100.100.100" ];
      domains = [ ];
    };
  };
}
