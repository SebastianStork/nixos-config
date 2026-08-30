{ config, inputs, ... }:
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
    };
    environmentFiles = [ config.sops.templates."hermes-matrix.env".path ];
    settings = {
      model = {
        default = "gpt-5.6-sol";
        provider = "openai-codex";
      };
      agent.reasoning_effort = "medium";
    };
  };

  custom.persistence.directories = [ "/var/lib/hermes" ];
}
