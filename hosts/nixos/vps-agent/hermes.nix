{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  sops = {
    secrets = {
      "hermes/matrix/access-token" = { };
      "hermes/matrix/allowed-users" = { };
      "hermes/matrix/recovery-key" = { };
    };
    templates."hermes-matrix.env" = {
      content = ''
        MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/matrix/access-token"}
        MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/matrix/allowed-users"}
        MATRIX_RECOVERY_KEY=${config.sops.placeholder."hermes/matrix/recovery-key"}
      '';
      restartUnits = [ "hermes-agent.service" ];
    };
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environment = {
      MATRIX_HOMESERVER = "https://matrix.org";
      MATRIX_E2EE_MODE = "required";
      MATRIX_REACTIONS = "false";
    };
    environmentFiles = [ config.sops.templates."hermes-matrix.env".path ];
    settings = {
      model = {
        default = "gpt-5.6-terra";
        provider = "openai-codex";
      };
      agent.reasoning_effort = "medium";
      delegation = {
        model = "gpt-5.6-sol";
        provider = "openai-codex";
        reasoning_effort = "high";
      };
    };
    backend.mode = "dashboard";
  };

  systemd.services.hermes-agent.restartTriggers = [
    (lib.toJSON config.services.hermes-agent.environment)
  ];

  custom =
    let
      dashboardDomain = "hermes.${config.networking.domain}";
      dashboardPort = config.services.hermes-agent.backend.port;
    in
    {
      services.caddy.virtualHosts.${dashboardDomain}.extraConfig = ''
        reverse_proxy localhost:${lib.toString dashboardPort} {
          header_up Host 127.0.0.1:${lib.toString dashboardPort}
          header_up Origin http://127.0.0.1:${lib.toString dashboardPort}
        }
      '';

      persistence.directories = [ "/var/lib/hermes" ];

      meta.sites.${dashboardDomain} = {
        title = "Hermes Agent";
        icon = "sh:hermes-agent";
      };
    };
}
