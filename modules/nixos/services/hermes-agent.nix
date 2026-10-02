{
  config,
  inputs,
  self,
  lib,
  pkgs,
  allHosts,
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
    homeAssistantDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.home-assistant)
        |> lib.filter (homeAssistant: homeAssistant.enable)
        |> lib.map (homeAssistant: homeAssistant.domain)
        |> self.lib.atMostOne "enabled Home Assistant instance";
    };
    trekDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.trek)
        |> lib.filter (trek: trek.enable)
        |> lib.map (trek: trek.domain)
        |> self.lib.atMostOne "enabled Trek instance";
    };
    forwardAuth = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain || cfg.forwardAuth;
      message = self.lib.mkUnprotectedMessage "Hermes Agent";
    };

    sops = {
      secrets = {
        "hermes/matrix/access-token" = { };
        "hermes/matrix/allowed-users" = { };
        "hermes/matrix/recovery-key" = { };
        "hermes/home-assistant/access-token" = lib.mkIf (cfg.homeAssistantDomain != null) { };
      };
      templates = {
        "hermes.env" = {
          content = ''
            MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
            MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
            MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
            ${lib.optionalString (cfg.homeAssistantDomain != null)
              "HASS_TOKEN=${config.sops.placeholder."hermes/home-assistant/access-token"}"
            }
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
        HASS_URL = lib.mkIf (cfg.homeAssistantDomain != null) "https://${cfg.homeAssistantDomain}";
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
      mcpServers.trek = lib.mkIf (cfg.trekDomain != null) {
        url = "https://${cfg.trekDomain}/mcp";
        auth = "oauth";
      };
      backend = {
        mode = "dashboard";
        inherit (cfg) port;
      };
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
        hermes-agent.restartTriggers = hermesRestartTriggers;
        hermes-backend.restartTriggers = hermesRestartTriggers;
      };

    custom = {
      services.caddy.virtualHosts.${cfg.domain} = {
        forwardAuth = {
          enable = cfg.forwardAuth;
          bypassPaths = [ "/api/health" ];
        };
        extraConfig = ''
          reverse_proxy localhost:${lib.toString cfg.port} {
            header_up Host 127.0.0.1:${lib.toString cfg.port}
            header_up Origin http://127.0.0.1:${lib.toString cfg.port}
          }
        '';
      };

      persistence.directories = [ config.services.hermes-agent.stateDir ];

      meta.sites.${cfg.domain} = {
        title = "Hermes Agent";
        icon = "hermes-agent";
        checkPath = "/api/health";
      };
    };
  };
}
