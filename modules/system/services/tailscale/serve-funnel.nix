{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.tailscale;
in
{
  options.custom.services.tailscale.serve = {
    isFunnel = lib.mkEnableOption "";
    target = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
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
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStartPre = "${lib.getExe pkgs.tailscale} cert --min-validity 120h ${config.networking.hostName}.${cfg.domain}";
            ExecStart = "${lib.getExe pkgs.tailscale} ${mode} --bg ${cfg.serve.target}";
            ExecStop = "${lib.getExe pkgs.tailscale} ${mode} reset";
            Restart = "on-failure";
          };
        };

        tailscaled-set.after = [ "tailscaled-autoconnect.service" ];
      };
  };
}
