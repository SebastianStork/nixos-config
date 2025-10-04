{
  config,
  inputs,
  osConfig,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.programs.vscode.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.vscode.enable {
    programs.vscode = {
      enable = true;
      package = pkgs-unstable.vscodium;
      profiles.default.extensions =
        let
          inherit (inputs.vscode-extensions.extensions.${pkgs.system}) open-vsx;
        in
        [
          # Language Servers
          open-vsx.jnoortheen.nix-ide
          open-vsx.llvm-vs-code-extensions.vscode-clangd
          open-vsx.rust-lang.rust-analyzer

          # Theming
          open-vsx.github.github-vscode-theme
          open-vsx.pkief.material-icon-theme
        ];
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
            "window.menuBarVisibility" = "toggle";
            "window.titleBarStyle" = "native";
            "window.customTitleBarVisibility" = "never";
            "git.autofetch" = true;
            "git.confirmSync" = false;
            "git.suggestSmartCommit" = false;
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = lib.getExe pkgs.nixd;
            "nix.formatterPath" = lib.getExe pkgs.nixfmt-rfc-style;
            "nix.serverSettings.nixd.formatting.command" = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
          }
        );
      in
      [
        "f+ %h/.config/VSCodium/User/settings.json - - - - ${settings}"
        "f+ %h/.config/VSCodium/User/settings-default.json - - - - ${settings}"
      ];

    home.shellAliases.code = "codium";
  };
}
