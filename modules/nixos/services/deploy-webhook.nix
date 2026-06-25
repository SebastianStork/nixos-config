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
      rc=0
      systemctl start --wait nixos-rebuild.service || rc=$?
      journalctl --invocation=0 --unit=nixos-rebuild.service --output=cat --no-pager
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
    systemd.services.nixos-rebuild = {
      description = "NixOS rebuild from latest commit";
      restartIfChanged = false;
      path = [
        pkgs.nh
        pkgs.nix
        pkgs.git
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        nh os switch \
          --bypass-root-check \
          --refresh \
          --no-build-output \
          --show-activation-logs \
          git+https://codeberg.org/SebastianStork/nixos-config
      '';
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
