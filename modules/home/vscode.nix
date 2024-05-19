{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.vscode.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.vscode.enable {
    programs.vscode = {
      enable = true;

      package = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions =
          let
            open-ext = inputs.nix-vscode-extensions.extensions.${pkgs.system}.open-vsx;
          in
          [
            open-ext.jnoortheen.nix-ide
            open-ext.yzhang.markdown-all-in-one

            open-ext.github.github-vscode-theme
            open-ext.pkief.material-icon-theme
          ];
      };
    };

    systemd.user.tmpfiles.rules =
      let
        settings = builtins.replaceStrings [ "," ] [ ",\\n" ] (
          builtins.toJSON {
            "workbench.colorTheme" =
              {
                dark = "GitHub Dark";
                light = "GitHub Light";
              }
              .${config.myConfig.de.theme};
            "workbench.iconTheme" = "material-icon-theme";
            "editor.fontFamily" = "JetBrainsMono Nerd Font";
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "extensions.autoCheckUpdates" = false;
            "files.autoSave" = "afterDelay";
            "git.autofetch" = true;
            "git.confirmSync" = false;
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "${lib.getExe pkgs.nil}";
            "update.mode" = "none";
            "git.suggestSmartCommit" = false;
            "workbench.sideBar.location" = "right";
            "editor.renderWhitespace" = "none";
            "editor.minimap.enabled" = false;
            "window.menuBarVisibility" = "toggle";
            "workbench.editor.decorations.colors" = false;
          }
        );
      in
      [
        "f+ %h/.config/VSCodium/User/settings.json - - - - ${settings}"
        "f+ %h/.config/VSCodium/User/settings-default.json - - - - ${settings}"
      ];
  };
}
