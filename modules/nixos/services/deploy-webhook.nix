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
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      old_unit=$(systemctl cat webhook.service 2>/dev/null || true)

      rc=0
      systemctl start --wait nixos-rebuild.service || rc=$?
      journalctl --invocation=0 --unit=nixos-rebuild.service --output=cat --no-pager

      new_unit=$(systemctl cat webhook.service 2>/dev/null || true)
      if [ "$old_unit" != "$new_unit" ]; then
        systemd-run --on-active=30 -- systemctl restart webhook.service
      fi

      exit "$rc"
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
    systemd.services = {
      webhook.restartIfChanged = false;

      nixos-rebuild = {
        description = "NixOS rebuild from latest commit";
        path = [
          pkgs.nixos-rebuild
          pkgs.git
          pkgs.dix
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          old_system=$(readlink /run/current-system)

          echo " "
          echo "==> nixos-rebuild"
          nixos-rebuild switch --flake git+https://codeberg.org/SebastianStork/nixos-config --refresh

          echo " "
          echo "==> diff"
          dix "$old_system" /run/current-system
          echo " "
        '';
      };
    };

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
      handle /hooks/deploy {
        reverse_proxy localhost:${lib.toString cfg.webhookPort}
      }
    '';
  };
}
