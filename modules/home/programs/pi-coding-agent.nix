{
  config,
  inputs,
  lib,
  pkgs-unstable,
  ...
}:
{
  imports = [ "${inputs.home-manager-unstable}/modules/programs/pi-coding-agent.nix" ];

  options.custom.programs.pi-coding-agent.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.pi-coding-agent.enable {
    programs.pi-coding-agent = {
      enable = true;
      package = pkgs-unstable.pi-coding-agent;

      settings = {
        lastChangelogVersion = "0.80.3";
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.5";
        defaultThinkingLevel = "high";
        hideThinkingBlock = true;
        theme = config.custom.theme;
        editorPaddingX = 1;
      };

      context = ''
        # Agent Rules

        - Do what has been asked; nothing more, nothing less.
        - Do not start implementing changes until the approach has been discussed and confirmed.
        - If requirements are unclear, ask clarifying questions before editing files.
        - Prefer small, focused changes over broad refactors.
        - Do not change unrelated files or behavior.
        - Never create files unless they are necessary for the requested task.
        - Prefer editing existing files over creating new ones.
        - Never proactively create documentation files unless explicitly requested.
      '';
    };
  };
}
