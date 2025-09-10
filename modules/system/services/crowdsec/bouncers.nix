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

  options.custom.services.crowdsec.bouncers.firewall = lib.mkEnableOption "";

  config = lib.mkIf cfg.bouncers.firewall {
    services.crowdsec-firewall-bouncer = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec-firewall-bouncer;
      settings = {
        api_key = "cs-firewall-bouncer";
        api_url = "http://localhost:${builtins.toString cfg.apiPort}";
      };
    };

    systemd.services.crowdsec.serviceConfig.ExecStartPre = lib.mkAfter (
      lib.getExe (
        pkgs.writeShellApplication {
          name = "crowdsec-add-bouncer";
          text = ''
            if ! cscli bouncers list | grep -q "firewall"; then
              cscli bouncers add "firewall" --key "cs-firewall-bouncer"
            fi
          '';
        }
      )
    );
  };
}
