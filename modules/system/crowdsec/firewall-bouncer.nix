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
        api_url = "http://127.0.0.1:${toString cfg.apiPort}";
      };
    };

    systemd.services.crowdsec.preStart = ''
      if ! cscli bouncers list | grep -q "firewall-bouncer"; then
        cscli bouncers add "firewall-bouncer" --key "cs-firewall-bouncer"
      fi
    '';
  };
}
