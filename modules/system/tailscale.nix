{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig.tailscale;
in
{
  options.myConfig.tailscale = {
    enable = lib.mkEnableOption "";
    subdomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = config.networking.hostName;
    };
    ssh.enable = lib.mkEnableOption "";
    exitNode.enable = lib.mkEnableOption "";
    serve = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.optionalAttrs config.myConfig.sops.enable {
      "tailscale-auth-key" = { };
    };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale-auth-key".path or "/run/secrets/tailscale-auth-key";
      openFirewall = true;
      useRoutingFeatures = if (cfg.exitNode.enable || (cfg.serve != null)) then "server" else "client";
      extraUpFlags = [ "--reset=true" ];
      extraSetFlags = [
        "--hostname=${cfg.subdomain}"
        "--ssh=${lib.boolToString cfg.ssh.enable}"
        "--advertise-exit-node=${lib.boolToString cfg.exitNode.enable}"
      ];
    };

    systemd.services.tailscaled-set.after = [ "tailscaled-autoconnect.service" ];

    systemd.services.tailscaled-serve = lib.mkIf (cfg.serve != null) {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${lib.getExe pkgs.tailscale} cert ${cfg.subdomain}.${config.networking.domain}
        ${lib.getExe pkgs.tailscale} serve reset
        ${lib.getExe pkgs.tailscale} serve --bg ${cfg.serve}
      '';
    };
  };
}
