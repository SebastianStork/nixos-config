{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.deploy-webhook;

  deploy = pkgs.writeShellApplication {
    name = "deploy";
    runtimeInputs = [
      pkgs.nixos-rebuild
      pkgs.git
      pkgs.dix
      pkgs.systemd
    ];
    text = ''
      old_system=$(readlink /run/current-system)
      old_unit=$(systemctl cat webhook.service 2>/dev/null || true)
      nixos-rebuild switch --flake git+https://codeberg.org/SebastianStork/nixos-config --refresh
      dix "$old_system" /run/current-system
      new_unit=$(systemctl cat webhook.service 2>/dev/null || true)
      if [ "$old_unit" != "$new_unit" ]; then
        systemd-run --on-active=30 -- systemctl restart webhook.service
      fi
    '';
  };
in
{
  options.custom.services.deploy-webhook = {
    enable = lib.mkEnableOption "";
    webhookPort = lib.mkOption {
      type = lib.types.port;
      default = 44519;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.webhook.restartIfChanged = false;

    services.webhook = {
      enable = true;
      ip = "127.0.0.1";
      port = cfg.webhookPort;
      hooks.deploy = {
        execute-command = "/run/wrappers/bin/sudo";
        pass-arguments-to-command = lib.singleton {
          source = "string";
          name = lib.getExe deploy;
        };
        include-command-output-in-response = true;
        include-command-output-in-response-on-error = true;
      };
    };

    security.sudo.extraRules = lib.singleton {
      users = [ "webhook" ];
      commands = lib.singleton {
        command = lib.getExe deploy;
        options = [ "NOPASSWD" ];
      };
    };

    custom.services.caddy.virtualHosts.${config.custom.networking.overlay.fqdn}.extraConfig = ''
      handle /hooks/* {
        reverse_proxy localhost:${toString cfg.webhookPort}
      }
    '';
  };
}
