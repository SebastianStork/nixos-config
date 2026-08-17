{ inputs, ... }:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
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
