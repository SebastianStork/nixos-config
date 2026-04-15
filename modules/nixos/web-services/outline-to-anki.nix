{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.outline-to-anki;

  dataDir = "/var/lib/outline-to-anki";
in
{
  options.custom.web-services.outline-to-anki = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    webhookPort = lib.mkOption {
      type = lib.types.port;
      default = 44519;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "outline-to-anki/ssh-key".restartUnits = [ "outline-to-anki.service" ];
        "outline-to-anki/api-token".restartUnits = [ "outline-to-anki.service" ];
      };
      templates."outline-to-anki-config.toml".content = ''
        [outline]
        url = "https://${config.custom.web-services.outline.domain}"
        api_token = "${config.sops.placeholder."outline-to-anki/api-token"}"
        output_dir = "${dataDir}"
      '';
    };

    systemd.services.outline-to-anki = {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      startAt = "hourly";
      path = [
        pkgs.nix
        pkgs.git
        pkgs.openssh
      ];
      environment.GIT_SSH_COMMAND = "ssh -i ${
        config.sops.secrets."outline-to-anki/ssh-key".path
      } -o IdentitiesOnly=yes -o StrictHostKeyChecking=no";
      script = "nix run git+ssh://git@github.com/NebelToast/anki_outline --refresh -- -c ${
        config.sops.templates."outline-to-anki-config.toml".path
      }";
    };

    services.webhook = {
      enable = true;
      ip = "127.0.0.1";
      port = cfg.webhookPort;
      hooks.outline-to-anki = {
        execute-command = "/run/wrappers/bin/sudo";
        pass-arguments-to-command = [
          {
            source = "string";
            name = lib.getExe' pkgs.systemd "systemctl";
          }
          {
            source = "string";
            name = "start";
          }
          {
            source = "string";
            name = "outline-to-anki.service";
          }
        ];
        response-message = "outline-to-anki started";
      };
    };

    security.sudo.extraRules = lib.singleton {
      users = [ "webhook" ];
      commands = lib.singleton {
        command = "${lib.getExe' pkgs.systemd "systemctl"} start outline-to-anki.service";
        options = [ "NOPASSWD" ];
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
        handle /update {
          rewrite /hooks/outline-to-anki
          reverse_proxy localhost:${toString cfg.webhookPort}
        }

        root ${dataDir}
        file_server browse
      '';

      meta.sites.${cfg.domain} = {
        title = "Anki Decks";
        icon = "sh:anki";
      };
    };
  };
}
