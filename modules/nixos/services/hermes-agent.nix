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
    homeAssistantUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.home-assistant)
        |> lib.filter (homeAssistant: homeAssistant.enable)
        |> lib.map (homeAssistant: "https://${homeAssistant.domain}")
        |> self.lib.atMostOne "enabled Home Assistant instance";
    };
    trekUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.trek)
        |> lib.filter (trek: trek.enable)
        |> lib.map (trek: "https://${trek.domain}/mcp")
        |> self.lib.atMostOne "enabled Trek instance";
    };
    searxngUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.searxng)
        |> lib.filter (searxng: searxng.enable && searxng.api.allowHermes)
        |> lib.map (searxng: "http://${searxng.domain}:${lib.toString searxng.port}")
        |> self.lib.atMostOne "enabled SearXNG instance";
    };
    forwardAuth = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = lib.singleton {
          assertion = self.lib.isPrivateDomain cfg.domain || cfg.forwardAuth;
          message = self.lib.mkUnprotectedMessage "Hermes Agent";
        };

        sops = {
          secrets = {
            "hermes/matrix/access-token" = { };
            "hermes/matrix/allowed-users" = { };
            "hermes/matrix/recovery-key" = { };
            "hermes/codeberg/access-token" = { };
            "hermes/openrouter/api-key" = { };
          };
          templates = {
            "hermes.env" = {
              content = ''
                MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
                MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
                MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
                CODEBERG_TOKEN=${config.sops.placeholder."hermes/codeberg/access-token"}
                OPENROUTER_API_KEY=${config.sops.placeholder."hermes/openrouter/api-key"}
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
            pkgs.python3
            pkgs.ripgrep
          ]
          ++ lib.optionals config.custom.web-services.calibre-server.enable [
            pkgs.calibre
            pkgs.fanficfare
          ];
          environment = {
            MATRIX_HOMESERVER = "https://matrix.org";
            MATRIX_E2EE_MODE = "required";
            MATRIX_REACTIONS = "false";
            MATRIX_AUTO_THREAD = "false";
            MATRIX_SESSION_SCOPE = "room";
            OBSIDIAN_VAULT_PATH = "${config.services.hermes-agent.stateDir}/Vault";
          };
          environmentFiles = [ config.sops.templates."hermes.env".path ];
          settings = {
            agent.reasoning_effort = "medium";
            agent.reasoning_overrides."openrouter/deepseek/deepseek-v4.1-flash-1017" = "high";
            approvals.destructive_slash_confirm = false;
            auxiliary.background_review.enabled = false;
            curator.prune_builtins = false;
            delegation = {
              fallback_providers = lib.singleton {
                model = "deepseek/deepseek-v4.1-flash-1017";
                provider = "openrouter";
              };
              max_concurrent_children = 3;
              model = "gpt-5.6-terra";
              provider = "openai-codex";
              reasoning_effort = "medium";
            };
            display.platforms.matrix.tool_preview_length = 1000; # Work around Hermes treating 0 as a 40-character limit in Matrix
            fallback_providers = lib.singleton {
              model = "anthropic/claude-sonnet-5.5";
              provider = "openrouter";
            };
            matrix.require_mention = false;
            model = {
              default = "gpt-5.6-sol";
              provider = "openai-codex";
            };
            stt = {
              language = "";
              local.model = "small";
            };
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
      }

      (lib.mkIf (cfg.homeAssistantUrl != null) (
        let
          catalog = "${inputs.hermes-agent}/plugin-catalog/homeassistant.yaml" |> lib.readFile;
          catalogValue =
            key:
            catalog
            |> lib.splitString "\n"
            |> lib.findFirst (lib.hasPrefix "${key}: ") (
              throw "Hermes plugin catalog entry for Home Assistant has no ${key}"
            )
            |> lib.removePrefix "${key}: ";
          plugin =
            let
              source = builtins.fetchGit {
                url = catalogValue "repo";
                rev = catalogValue "sha";
                name = "homeassistant";
              };
            in
            pkgs.runCommand "homeassistant" { } "cp -r ${source}/${catalogValue "subdir"} $out";
          restartTriggers = config.services.hermes-agent.extraPlugins |> lib.toJSON |> lib.singleton;
        in
        {
          sops = {
            secrets."hermes/home-assistant/access-token" = { };
            templates."hermes.env".content = ''
              HASS_TOKEN=${config.sops.placeholder."hermes/home-assistant/access-token"}
            '';
          };

          services.hermes-agent = {
            extraPlugins = [ plugin ];
            environment.HASS_URL = cfg.homeAssistantUrl;
            settings.plugins.enabled = [ "homeassistant" ];
          };

          systemd.services = {
            hermes-agent.restartTriggers = restartTriggers;
            hermes-backend.restartTriggers = restartTriggers;
          };
        }
      ))

      (lib.mkIf (cfg.trekUrl != null) {
        services.hermes-agent.mcpServers.trek = {
          url = cfg.trekUrl;
          auth = "oauth";
        };
      })

      (lib.mkIf (cfg.searxngUrl != null) {
        services.hermes-agent = {
          environment.SEARXNG_URL = cfg.searxngUrl;
          settings.web.search_backend = "searxng";
        };
      })
    ]
  );
}
