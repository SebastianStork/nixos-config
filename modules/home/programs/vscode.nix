{
  config,
  inputs,
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
      profiles.default = {
        extensions =
          let
            inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) open-vsx;
          in
          [
            open-vsx.jnoortheen.nix-ide
            open-vsx.aaron-bond.better-comments
            open-vsx.llvm-vs-code-extensions.vscode-clangd
            open-vsx.nefrob.vscode-just-syntax

            open-vsx.github.github-vscode-theme
            open-vsx.pkief.material-icon-theme
          ];
        userSettings = {
          "workbench.colorTheme" =
            {
              dark = "GitHub Dark";
              light = "GitHub Light";
            }
            .${config.custom.theme};
          "workbench.iconTheme" = "material-icon-theme";
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "extensions.autoCheckUpdates" = false;
          "files.autoSave" = "afterDelay";
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${lib.getExe pkgs.nixd}";
          "update.mode" = "none";
          "git.suggestSmartCommit" = false;
          "workbench.sideBar.location" = "right";
          "editor.renderWhitespace" = "none";
          "editor.minimap.enabled" = false;
          "window.menuBarVisibility" = "toggle";
          "workbench.editor.decorations.colors" = false;
          "window.titleBarStyle" = "native";
          "window.customTitleBarVisibility" = "never";
        };
      };
    };
  };
}
