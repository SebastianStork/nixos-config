{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.vscode.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.vscode.enable {
    programs.vscode = {
      enable = true;
      profiles.default = {
        extensions =
          let
            vscode-extensions =
              inputs.vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.forVSCodeVersion
                config.programs.vscode.package.version;
            inherit (vscode-extensions) open-vsx vscode-marketplace;

            # https://github.com/nix-community/nix-vscode-extensions?tab=readme-ov-file#unfree-extensions
            resetLicense =
              drv:
              drv.overrideAttrs (prev: {
                meta = prev.meta // {
                  license = [ ];
                };
              });

          in
          [
            # Theming
            open-vsx.github.github-vscode-theme
            open-vsx.pkief.material-icon-theme

            # Language Servers
            open-vsx.jnoortheen.nix-ide
            open-vsx.llvm-vs-code-extensions.vscode-clangd
            open-vsx.rust-lang.rust-analyzer

            # AI
            (resetLicense vscode-marketplace.github.copilot-chat)
          ];
      };
    };

    systemd.user.tmpfiles.rules =
      let
        settings = lib.replaceStrings [ "," ] [ ",\\n" ] (
          builtins.toJSON {
            "extensions.autoCheckUpdates" = false;
            "editor.fontFamily" = "JetBrainsMono Nerd Font";
            "workbench.iconTheme" = "material-icon-theme";
            "workbench.colorTheme" =
              {
                dark = "GitHub Dark";
                light = "GitHub Light";
              }
              .${config.custom.theme};
            "workbench.sideBar.location" = "right";
            "workbench.editor.decorations.colors" = false;
            "editor.renderWhitespace" = "none";
            "editor.minimap.enabled" = false;
            "editor.formatOnSave" = true;
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "files.autoSave" = "afterDelay";
            "update.mode" = "none";
            "window.titleBarStyle" = "custom";
            "git.autofetch" = true;
            "git.confirmSync" = false;
            "git.suggestSmartCommit" = false;
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = lib.getExe pkgs.nixd;
            "nix.formatterPath" = lib.getExe pkgs.nixfmt-rfc-style;
            "nix.serverSettings.nixd.formatting.command" = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
            "github.copilot.enable" = {
              "*" = false;
            };
          }
        );
      in
      [
        "f+ %h/.config/Code/User/settings.json - - - - ${settings}"
        "f+ %h/.config/Code/User/settings-default.json - - - - ${settings}"
      ];
  };
}
