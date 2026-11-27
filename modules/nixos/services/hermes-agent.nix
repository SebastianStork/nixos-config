{
  config,
  inputs,
  self,
  lib,
  pkgs,
  pkgs-unstable,
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
    doBackups = lib.mkEnableOption "";
    webapp = {
      enable = lib.mkEnableOption "";
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9120;
      };
      oidcIssuer = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default =
          allHosts
          |> lib.attrValues
          |> lib.map (host: (self.lib.uncheckedHostConfig host).custom.services.private-auth)
          |> lib.filter (privateAuth: privateAuth.enable)
          |> lib.map (privateAuth: "https://${privateAuth.domain}")
          |> self.lib.exactlyOne "enabled private auth instance";
      };
    };
    integrations = {
      homeAssistant.url = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default =
          allHosts
          |> lib.attrValues
          |> lib.map (host: host.config.custom.web-services.home-assistant)
          |> lib.filter (homeAssistant: homeAssistant.enable)
          |> lib.map (homeAssistant: "https://${homeAssistant.domain}")
          |> self.lib.atMostOne "enabled Home Assistant instance";
      };
      trek.url = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default =
          allHosts
          |> lib.attrValues
          |> lib.map (host: host.config.custom.web-services.trek)
          |> lib.filter (trek: trek.enable)
          |> lib.map (trek: "https://${trek.domain}/mcp")
          |> self.lib.atMostOne "enabled Trek instance";
      };
      searxng.url = lib.mkOption {
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
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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
              restartUnits = [ "hermes-agent.service" ];
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
              clarify_timeout = 600;
            };
            approvals.destructive_slash_confirm = false;
            auxiliary =
              let
                deepseek = {
                  model = "deepseek/deepseek-v4.1-flash-1017";
                  provider = "openrouter";
                };
              in
              {
                approval = deepseek;
                background_review.enabled = false;
                compression = deepseek;
                curator = deepseek;
                mcp = deepseek;
                memory_query_rewrite = deepseek;
                monitor = deepseek;
                title_generation = deepseek;
              };
            curator.prune_builtins = false;
            delegation = {
              fallback_providers = lib.singleton {
                model = "gpt-5.6-terra";
                provider = "openai-codex";
              };
              max_concurrent_children = 3;
              model = "deepseek/deepseek-v4.1-flash-1017";
              provider = "openrouter";
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
        };

        systemd.services.hermes-agent.restartTriggers = [
          (lib.toJSON config.services.hermes-agent.environment)
          (lib.toJSON config.services.hermes-agent.environmentFiles)
          (lib.toJSON config.services.hermes-agent.mcpServers)
          (lib.toJSON config.services.hermes-agent.settings)
        ];

        nix.settings.allowed-users = [ config.services.hermes-agent.user ];

        custom = {
          services.restic.backups.hermes-agent = lib.mkIf cfg.doBackups {
            conflictingServices = [ "hermes-agent.service" ];
            paths = [ config.services.hermes-agent.stateDir ];
          };

          persistence.directories = [ config.services.hermes-agent.stateDir ];
        };
      }

      (lib.mkIf cfg.webapp.enable {
        assertions = lib.singleton {
          assertion = self.lib.isPrivateDomain cfg.webapp.domain;
          message = self.lib.mkUnprotectedMessage "Hermes Agent";
        };

        services.hermes-agent.settings = {
          dashboard.oauth = {
            provider = "self-hosted";
            self_hosted = {
              issuer = cfg.webapp.oidcIssuer;
              client_id = "hermes";
            };
          };
          webapp = {
            enabled = true;
            host = "127.0.0.1";
            public_url = "https://${cfg.webapp.domain}";
            inherit (cfg.webapp) port;
          };
        };

        custom = {
          services = {
            caddy.virtualHosts.${cfg.webapp.domain} = {
              inherit (cfg.webapp) port;
              allowedGroups = [ "client" ];
            };

            private-auth.oidcClients.hermes = {
              clientName = "Hermes";
              public = true;
              redirectUris = [ "https://${cfg.webapp.domain}/auth/callback" ];
            };
          };

          meta.sites.${cfg.webapp.domain} = {
            title = "Hermes Agent";
            icon = "hermes-agent";
            checkPath = "/api/health";
          };
        };
      })

      (lib.mkIf config.custom.web-services.calibre-server.enable (
        let
          camoufoxRelease = {
            version = "v159.0-beta.43";
            hash = "9315ff337b730b697a17298b37575945036a2607b888759e900bc31f7f910cb2";
          };
          camoufoxLibraries = [
            pkgs.alsa-lib
            pkgs.at-spi2-core
            pkgs.cairo
            pkgs.dbus
            pkgs.fontconfig
            pkgs.freetype
            pkgs.gdk-pixbuf
            pkgs.glib
            pkgs.gtk3
            pkgs.libxkbcommon
            pkgs.pango
            pkgs.stdenv.cc.cc.lib
            pkgs.libx11
            pkgs.libxcomposite
            pkgs.libxcursor
            pkgs.libxdamage
            pkgs.libxext
            pkgs.libxfixes
            pkgs.libxi
            pkgs.libxrandr
            pkgs.libxrender
            pkgs.libxcb
          ];

          camoufox = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "camoufox";
            version = camoufoxRelease.version |> lib.removePrefix "v";

            src = pkgs.fetchurl {
              url = "https://github.com/daijro/camoufox/releases/download/${camoufoxRelease.version}/camoufox-${finalAttrs.version}-lin.x86_64.zip";
              hash = builtins.convertHash {
                inherit (camoufoxRelease) hash;
                hashAlgo = "sha256";
                toHashFormat = "sri";
              };
            };

            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.patchelf
              pkgs.unzip
            ];

            dontPatchELF = true;
            dontStrip = true;
            sourceRoot = ".";

            installPhase = ''
              runHook preInstall
              mkdir -p "$out/lib/camoufox"
              cp -r . "$out/lib/camoufox"
              mv "$out/lib/camoufox/camoufox-bin" "$out/lib/camoufox/camoufox-bin-unwrapped"
              patchelf \
                --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
                "$out/lib/camoufox/camoufox-bin-unwrapped"
              makeWrapper \
                "$out/lib/camoufox/camoufox-bin-unwrapped" \
                "$out/lib/camoufox/camoufox-bin" \
                --prefix LD_LIBRARY_PATH : "$out/lib/camoufox:${lib.makeLibraryPath camoufoxLibraries}"
              runHook postInstall
            '';

            meta = {
              description = "Anti-detect browser based on Firefox";
              homepage = "https://github.com/daijro/camoufox";
              license = lib.licenses.mpl20;
              platforms = [ "x86_64-linux" ];
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            };
          });

          browserforgePythonPath =
            [ pkgs-unstable.python314Packages.browserforge ] |> pkgs-unstable.python314Packages.makePythonPath;

          calibre = pkgs-unstable.calibre.overrideAttrs (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              cat > resources/system-camoufox.json <<'EOF'
              {"binary":"${camoufox}/lib/camoufox/camoufox-bin","resource_dir":"${camoufox}/lib/camoufox"}
              EOF
            '';

            preInstallCheck = ''
              export PYTHONPATH="${browserforgePythonPath}''${PYTHONPATH:+:$PYTHONPATH}"
            ''
            + (oldAttrs.preInstallCheck or "");

            preFixup = ''
              qtWrapperArgs+=(--prefix PYTHONPATH : "${browserforgePythonPath}")
            ''
            + (oldAttrs.preFixup or "");
          });

          fanFicFarePlugin = pkgs.fetchurl {
            url = "https://github.com/JimmXinu/FanFicFare/releases/download/v4.63.0/FanFicFarePlugin-v4.63.0.zip";
            hash = "sha256-drqxwoE6RqHig4U1ylyyCYf9vcxAnRPA3MnY0yVMy+Y=";
          };

          fanFicFare = pkgs.writeShellApplication {
            name = "fanficfare";
            runtimeInputs = [
              calibre
              pkgs.coreutils
              pkgs.util-linux
            ];
            text = ''
              state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/fanficfare-calibre"
              export CALIBRE_CONFIG_DIRECTORY="$state_dir/config"
              library_dir="$state_dir/library"
              installed_plugin="$CALIBRE_CONFIG_DIRECTORY/plugins/FanFicFare.zip"

              mkdir -p "$CALIBRE_CONFIG_DIRECTORY/plugins" "$library_dir"
              exec 9>"$state_dir/init.lock"
              flock 9

              if [[ ! -f "$library_dir/metadata.db" ]]; then
                calibredb --with-library "$library_dir" list >/dev/null
              fi

              if [[ ! -f "$installed_plugin" ]] || ! cmp --silent ${fanFicFarePlugin} "$installed_plugin"; then
                calibre-customize --add-plugin ${fanFicFarePlugin}
              fi

              flock --unlock 9
              exec calibre-debug --run-plugin FanFicFare -- \
                --library-path "$library_dir" \
                --option use_browser_cache=false \
                --option use_camoufox=directimages \
                --option connect_timeout=180 \
                "$@"
            '';
          };
        in
        {
          services.hermes-agent.extraPackages = [
            pkgs.calibre
            fanFicFare
          ];
        }
      ))

      (lib.mkIf (cfg.integrations.homeAssistant.url != null) (
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
            environment.HASS_URL = cfg.integrations.homeAssistant.url;
            settings.plugins.enabled = [ "homeassistant" ];
          };

          systemd.services.hermes-agent.restartTriggers = restartTriggers;
        }
      ))

      (lib.mkIf (cfg.integrations.trek.url != null) {
        services.hermes-agent.mcpServers.trek = {
          url = cfg.integrations.trek.url;
          auth = "oauth";
        };
      })

      (lib.mkIf (cfg.integrations.searxng.url != null) {
        services.hermes-agent = {
          environment.SEARXNG_URL = cfg.integrations.searxng.url;
          settings.web.search_backend = "searxng";
        };
      })

      (lib.mkIf (cfg.integrations.radicale.url != null) (
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
            url = "${cfg.integrations.radicale.url}/${cfg.integrations.radicale.ownerUsername}/"
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
