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
    radicale =
      let
        discoveredRadicale =
          allHosts
          |> lib.attrValues
          |> lib.map (host: host.config.custom.web-services.radicale)
          |> lib.filter (radicale: radicale.enable && radicale.allowHermes)
          |> self.lib.atMostOne "enabled Radicale instance allowing Hermes access";
      in
      {
        url = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = if discoveredRadicale == null then null else "https://${discoveredRadicale.domain}";
        };
        ownerUsername = lib.mkOption {
          type = lib.types.strMatching "[A-Za-z0-9_-]+";
          default = discoveredRadicale.ownerUsername;
        };
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
            "hermes/agentmail/api-key" = { };
          };
          templates = {
            "hermes.env" = {
              content = ''
                MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
                MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
                MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
                CODEBERG_TOKEN=${config.sops.placeholder."hermes/codeberg/access-token"}
                OPENROUTER_API_KEY=${config.sops.placeholder."hermes/openrouter/api-key"}
                AGENTMAIL_API_KEY=${config.sops.placeholder."hermes/agentmail/api-key"}
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
          mcpServers.agentmail = {
            url = "https://mcp.agentmail.to/mcp";
            headers."x-api-key" = "\${AGENTMAIL_API_KEY}";
            tools.include = [
              "list_inboxes"
              "search_inboxes"
              "get_inbox"
              "list_threads"
              "search_threads"
              "get_thread"
              "list_messages"
              "search_messages"
              "get_message"
              "get_attachment"
            ];
            sampling.enabled = false;
          };
          settings = {
            agent = {
              reasoning_effort = "medium";
              reasoning_overrides."openrouter/deepseek/deepseek-v4.1-flash-1017" = "high";
              disabled_toolsets = [ "browser" ];
            };
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
              (lib.toJSON config.services.hermes-agent.mcpServers)
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

      (lib.mkIf (cfg.radicale.url != null) (
        let
          stateDir = "${config.services.hermes-agent.stateDir}/calendar";
          vdirsyncerConfig = pkgs.writeText "vdirsyncer-calendar.conf" ''
            [general]
            status_path = "${stateDir}/status/"

            [pair calendars]
            a = "remote"
            b = "local"
            collections = ["from a"]

            [storage remote]
            type = "caldav"
            url = "${cfg.radicale.url}/${cfg.radicale.ownerUsername}/"
            username = "hermes"
            password.fetch = ["command", "${lib.getExe' pkgs.coreutils "cat"}", "${
              config.sops.secrets."hermes/radicale/password".path
            }"]

            [storage local]
            type = "filesystem"
            path = "${stateDir}/calendars/"
            fileext = ".ics"
          '';
          khalConfig = pkgs.writeText "khal-calendar.conf" ''
            [calendars]
              [[calendars]]
                path = ${stateDir}/calendars/*
                type = discover

            [sqlite]
              path = ${stateDir}/khal.db

            [locale]
              default_timezone = ${config.time.timeZone}
              local_timezone = ${config.time.timeZone}

            [default]
              default_calendar = hermes
          '';
          calendarSync = pkgs.writeShellApplication {
            name = "hermes-calendar-sync";
            runtimeInputs = [ pkgs.vdirsyncer ];
            text = ''
              export VDIRSYNCER_CONFIG=${vdirsyncerConfig}
              exec vdirsyncer "$@"
            '';
          };
          calendarCli = pkgs.writeShellApplication {
            name = "hermes-calendar";
            runtimeInputs = [ pkgs.khal ];
            text = ''
              exec khal -c ${khalConfig} "$@"
            '';
          };
        in
        {
          sops.secrets."hermes/radicale/password".owner = config.services.hermes-agent.user;

          services.hermes-agent.extraPackages = [
            calendarCli
            calendarSync
          ];

          systemd.tmpfiles.rules = [
            "d ${stateDir} 0700 ${config.services.hermes-agent.user} ${config.services.hermes-agent.group} - -"
            "d ${stateDir}/calendars 0700 ${config.services.hermes-agent.user} ${config.services.hermes-agent.group} - -"
            "d ${stateDir}/status 0700 ${config.services.hermes-agent.user} ${config.services.hermes-agent.group} - -"
          ];
        }
      ))
    ]
  );
}
