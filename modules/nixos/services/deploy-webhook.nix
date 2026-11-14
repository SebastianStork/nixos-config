{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.deploy-webhook;

  currentSystem = pkgs.writeShellApplication {
    name = "current-system";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      readlink /run/current-system
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "deploy";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      revision=$1
      unit="nixos-rebuild@$revision.service"

      rc=0
      systemctl start --wait "$unit" || rc=$?
      journalctl --invocation=0 --unit="$unit" --output=cat --no-pager
      if [[ "$rc" -eq 0 ]]; then
        printf '%s\n' "$revision" > ${cfg.deploymentTargetFile}
      fi
      exit "$rc"
    '';
  };

  deferDeploy = pkgs.writeShellApplication {
    name = "defer-deploy";
    text = ''
      printf '%s\n' "$1" > ${cfg.deploymentTargetFile}
    '';
  };

  diff = pkgs.writeShellApplication {
    name = "diff-closures";
    runtimeInputs = [ pkgs.dix ];
    text = ''
      dix "$1" /run/current-system
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
    deploymentTargetFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/nixos/deployment-target";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."nixos-rebuild@" = {
      description = "NixOS rebuild at revision %i";
      restartIfChanged = false;
      path = [
        pkgs.nh
        pkgs.nix
        pkgs.git
      ];
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      script = ''
        revision=$1
        nh os switch \
          --bypass-root-check \
          --refresh \
          --diff never \
          --no-nom \
          --show-activation-logs \
          "git+https://codeberg.org/SebastianStork/nixos-config?rev=$revision"
      '';
    };

    services.webhook = {
      enable = true;
      ip = "127.0.0.1";
      port = cfg.webhookPort;
      hooks = {
        current-system = {
          execute-command = lib.getExe currentSystem;
          include-command-output-in-response = true;
          include-command-output-in-response-on-error = true;
        };
        deploy = {
          execute-command = "/run/wrappers/bin/sudo";
          pass-arguments-to-command = [
            {
              source = "string";
              name = lib.getExe deploy;
            }
            {
              source = "payload";
              name = "revision";
            }
          ];
          http-methods = [ "POST" ];
          include-command-output-in-response = true;
          include-command-output-in-response-on-error = true;
        };
        defer-deploy = {
          execute-command = "/run/wrappers/bin/sudo";
          pass-arguments-to-command = [
            {
              source = "string";
              name = lib.getExe deferDeploy;
            }
            {
              source = "payload";
              name = "revision";
            }
          ];
          http-methods = [ "POST" ];
          include-command-output-in-response = true;
          include-command-output-in-response-on-error = true;
        };
        diff = {
          execute-command = lib.getExe diff;
          pass-arguments-to-command = lib.singleton {
            source = "payload";
            name = "old_closure";
          };
          http-methods = [ "POST" ];
          include-command-output-in-response = true;
          include-command-output-in-response-on-error = true;
        };
      };
    };

    security.sudo.extraRules = lib.singleton {
      users = [ "webhook" ];
      commands = [
        {
          command = lib.getExe deploy;
          options = [ "NOPASSWD" ];
        }
        {
          command = lib.getExe deferDeploy;
          options = [ "NOPASSWD" ];
        }
      ];
    };

    custom.services.caddy.virtualHosts.${config.networking.fqdn} = {
      extraConfig = ''
        handle /hooks/current-system {
          header Cache-Control "no-store"
          reverse_proxy localhost:${lib.toString cfg.webhookPort}
        }
        handle /hooks/deploy {
          reverse_proxy localhost:${lib.toString cfg.webhookPort}
        }
        handle /hooks/defer-deploy {
          reverse_proxy localhost:${lib.toString cfg.webhookPort}
        }
        handle /hooks/diff {
          reverse_proxy localhost:${lib.toString cfg.webhookPort}
        }
      '';
      extraAllowedGroups = [ "automation" ];
    };
  };
}
