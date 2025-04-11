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
    serve = {
      isFunnel = lib.mkEnableOption "";
      target = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale-auth-key" = { };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale-auth-key".path;
      openFirewall = true;
      useRoutingFeatures =
        if (cfg.exitNode.enable || (cfg.serve.target != null)) then "server" else "client";
      extraUpFlags = [ "--reset=true" ];
      extraSetFlags = [
        "--hostname=${cfg.subdomain}"
        "--ssh=${lib.boolToString cfg.ssh.enable}"
        "--advertise-exit-node=${lib.boolToString cfg.exitNode.enable}"
      ];
    };

    systemd.services =
      let
        mode = if cfg.serve.isFunnel then "funnel" else "serve";
      in
      {
        "tailscaled-${mode}" = lib.mkIf (cfg.serve.target != null) {
          after = [
            "tailscaled.service"
            "tailscaled-autoconnect.service"
          ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          preStart = "${lib.getExe pkgs.tailscale} cert --min-validity 120h ${cfg.subdomain}.${config.networking.domain}";
          script = "${lib.getExe pkgs.tailscale} ${mode} ${cfg.serve.target}";
        };

        tailscaled-set.after = [ "tailscaled-autoconnect.service" ];
      };
  };
}
