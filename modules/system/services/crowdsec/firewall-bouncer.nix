{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.crowdsec;
in
{
  imports = [ inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer ];

  options.custom.services.crowdsec.firewallBouncer.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.firewallBouncer.enable {
    services.crowdsec-firewall-bouncer = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec-firewall-bouncer;
      settings = {
        api_key = "cs-firewall-bouncer";
        api_url = "http://localhost:${builtins.toString cfg.apiPort}";
      };
    };

    systemd.services.crowdsec.serviceConfig.ExecStartPre = lib.mkAfter (
      pkgs.writeShellScript "crowdsec-add-bouncer" ''
        set -e
        if ! cscli bouncers list | grep -q "firewall"; then
          cscli bouncers add "firewall" --key "cs-firewall-bouncer"
        fi
      ''
    );
  };
}
