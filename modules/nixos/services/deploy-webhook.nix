{
  config,
  self,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.deploy-webhook;

  deploymentState = pkgs.writeShellApplication {
    name = "deployment-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      current_closure=$(readlink /run/current-system)
      target_closure=
      if [[ -s ${cfg.deploymentTargetFile} ]]; then
        IFS= read -r target_closure < ${cfg.deploymentTargetFile}
      fi

      jq --null-input --compact-output \
        --arg current_closure "$current_closure" \
        --arg target_closure "$target_closure" \
        '{ $current_closure, $target_closure }'
    '';
  };

  validateClosure = ''
    validate_closure() {
      if [[ "$1" != /nix/store/*-nixos-system-${lib.escapeShellArg config.networking.hostName}-* ]]; then
        echo "Expected a NixOS system store path for this host." >&2
        exit 1
      fi
    }
  '';

  writeDeploymentTarget = ''
    write_deployment_target() {
      mkdir --parents ${lib.escapeShellArg (lib.dirOf cfg.deploymentTargetFile)}
      printf '%s\n' "$1" > ${lib.escapeShellArg cfg.deploymentTargetFile}
    }
  '';

  deploy = pkgs.writeShellApplication {
    name = "deploy";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text =
      validateClosure
      + writeDeploymentTarget
      + ''
        closure=$1
        validate_closure "$closure"
        unit="nixos-deploy@$(systemd-escape --path "$closure").service"

        rc=0
        systemctl start --wait "$unit" || rc=$?
        journalctl --invocation=0 --unit="$unit" --output=cat --no-pager
        if [[ "$rc" -eq 0 ]]; then
          write_deployment_target "$closure"
        fi
        exit "$rc"
      '';
  };

  deferDeploy = pkgs.writeShellApplication {
    name = "defer-deploy";
    runtimeInputs = [ pkgs.coreutils ];
    text =
      validateClosure
      + writeDeploymentTarget
      + ''
        closure=$1
        validate_closure "$closure"
        write_deployment_target "$closure"
      '';
  };

  diff = pkgs.writeShellApplication {
    name = "diff-closures";
    runtimeInputs = [ (pkgs.packageAtLeast "dix" "3.0.0") ];
    text = ''
      dix diff "$1" /run/current-system
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
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain config.networking.fqdn;
      message = self.lib.mkInvalidConfigMessage "deployment webhook" "domain must be private";
    };

    systemd.services."nixos-deploy@" = {
      description = "Deploy NixOS system closure %f";
      restartIfChanged = false;
      path = [
        pkgs.nh
        pkgs.nix
      ];
      serviceConfig.Type = "oneshot";
      scriptArgs = "%f";
      script = validateClosure + ''
        closure=$1
        validate_closure "$closure"
        nix build --no-link --max-jobs 0 --builders "" "$closure"
        nh os switch \
          --bypass-root-check \
          --diff never \
          --no-nom \
          --show-activation-logs \
          "$closure"
      '';
    };

    services.webhook = {
      enable = true;
      ip = "127.0.0.1";
      port = cfg.webhookPort;
      hooks = {
        deployment-state = {
          execute-command = lib.getExe deploymentState;
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
              name = "closure";
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
              name = "closure";
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
        handle /hooks/deployment-state {
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
      allowedGroups = [ "automation" ];
      allowTrustedUnderlay = false;
    };
  };
}
