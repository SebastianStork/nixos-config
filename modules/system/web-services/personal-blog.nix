{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.personal-blog;

  dataDir = "/var/lib/personal-blog";
in
{
  options.custom.services.personal-blog = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    meta.domains.local = [ cfg.domain ];

    systemd.services.generate-blog = {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      startAt = "*:0/5"; # Every 5 minutes
      path = [ pkgs.nix ];
      script = "nix build github:SebastianStork/blog --out-link ${dataDir} --refresh";
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.files = dataDir;
  };
}
