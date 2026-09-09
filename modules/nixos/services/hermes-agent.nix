{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.hermes-agent;
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  options.custom.services.hermes-agent = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9119;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "hermes/matrix/access-token" = { };
        "hermes/matrix/allowed-users" = { };
        "hermes/matrix/recovery-key" = { };
        "hermes/home-assistant/access-token" = { };
      };
      templates = {
        "hermes.env" = {
          content = ''
            MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
            MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
            MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
            HASS_TOKEN=${config.sops.placeholder."hermes/home-assistant/access-token"}
          '';
          restartUnits = [
            "hermes-agent.service"
            "hermes-backend.service"
          ];
        };
      };
    };

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      extraPackages = [
        pkgs.tirith
        pkgs.jq
        pkgs.unzip
      ];
      environment = {
        MATRIX_HOMESERVER = "https://matrix.org";
        MATRIX_E2EE_MODE = "required";
        MATRIX_REACTIONS = "false";
        MATRIX_AUTO_THREAD = "false";
        MATRIX_SESSION_SCOPE = "room";
        HASS_URL = "https://home-assistant.${config.networking.domain}";
        OBSIDIAN_VAULT_PATH = "${config.services.hermes-agent.stateDir}/Vault";
      };
      environmentFiles = [ config.sops.templates."hermes.env".path ];
      settings = {
        approvals.destructive_slash_confirm = false;
        auxiliary.background_review.enabled = false;
        curator.prune_builtins = false;
        display.platforms.matrix.tool_preview_length = 1000; # Work around Hermes treating 0 as a 40-character limit in Matrix
        matrix.require_mention = false;
        security = {
          redact_secrets = true;
          allow_lazy_installs = false;
          tirith_enabled = true;
          tirith_fail_open = false;
        };
        skills = {
          create_dir = "~/.hermes/authored-skills";
          external_dirs = [ "~/.hermes/authored-skills" ];
        };
      };
      mcpServers.trek = {
        url = "https://trek.sprouted.cloud/mcp";
        auth = "oauth";
      };
      backend = {
        mode = "dashboard";
        inherit (cfg) port;
      };
    };

    # See https://github.com/NousResearch/hermes-agent/issues/103705
    users.users.hermes = {
      uid = 993;
      linger = true;
    };
    systemd.services =
      let
        hermesRestartTriggers = [
          (lib.toJSON config.services.hermes-agent.environment)
          (lib.toJSON config.services.hermes-agent.environmentFiles)
          (lib.toJSON config.services.hermes-agent.settings)
        ];
      in
      {
        hermes-agent =
          let
            uid = lib.toString config.users.users.hermes.uid;
          in
          {
            after = [ "user@${uid}.service" ];
            requires = [ "user@${uid}.service" ];
            environment = {
              XDG_RUNTIME_DIR = "/run/user/${uid}";
              DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
            };
            serviceConfig.BindReadOnlyPaths = [ "${pkgs.coreutils}/bin/true:/bin/true" ];

            restartTriggers = hermesRestartTriggers;
          };

        hermes-backend.restartTriggers = hermesRestartTriggers;
      };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
        reverse_proxy localhost:${lib.toString cfg.port} {
          header_up Host 127.0.0.1:${lib.toString cfg.port}
          header_up Origin http://127.0.0.1:${lib.toString cfg.port}
        }
      '';

      persistence.directories = [ config.services.hermes-agent.stateDir ];

      meta.sites.${cfg.domain} = {
        title = "Hermes Agent";
        icon = "sh:hermes-agent";
      };
    };
  };
}
