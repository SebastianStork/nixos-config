{
  config,
  inputs,
  lib,
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
        "hermes-matrix.env" = {
          content = ''
            MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
            MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
            MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
          '';
          restartUnits = [ "hermes-agent.service" ];
        };
        "hermes-home-assistant.env" = {
          content = "HASS_TOKEN=${config.sops.placeholder."hermes/home-assistant/access-token"}";
          restartUnits = [ "hermes-agent.service" ];
        };
      };
    };

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environment = {
        MATRIX_HOMESERVER = "https://matrix.org";
        MATRIX_E2EE_MODE = "required";
        MATRIX_REACTIONS = "false";
        HASS_URL = "https://home-assistant.${config.networking.domain}";
        HASS_TOKEN = config.sops.secrets."hermes/home-assistant/access-token".path;
        OBSIDIAN_VAULT_PATH = "${config.services.hermes-agent.stateDir}/Vault";
      };
      environmentFiles = [
        config.sops.templates."hermes-matrix.env".path
        config.sops.templates."hermes-home-assistant.env".path
      ];
      settings = {
        model = {
          default = "gpt-5.6-terra";
          provider = "openai-codex";
        };
        agent.reasoning_effort = "high";
        delegation = {
          model = "gpt-5.6-sol";
          provider = "openai-codex";
          reasoning_effort = "medium";
        };
        skills.create_dir = "~/.hermes/authored-skills";
      };
      backend = {
        mode = "dashboard";
        inherit (cfg) port;
      };
    };

    systemd.services.hermes-agent.restartTriggers = [
      (lib.toJSON config.services.hermes-agent.environment)
    ];

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
