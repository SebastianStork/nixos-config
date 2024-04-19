{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.vscode.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.vscode.enable {
        home.packages = [pkgs.nil];

        programs.vscode = {
            enable = true;
            package = pkgs.vscodium;

            mutableExtensionsDir = false;
            extensions = [
                pkgs.vscode-extensions.jnoortheen.nix-ide
                pkgs.vscode-extensions.pkief.material-icon-theme
            ];
        };

        systemd.user.tmpfiles.rules = let
            settings = builtins.replaceStrings [","] [",\\n"] (builtins.toJSON {
                "editor.fontFamily" = "JetBrainsMono Nerd Font";
                "explorer.confirmDelete" = false;
                "explorer.confirmDragAndDrop" = false;
                "extensions.autoCheckUpdates" = false;
                "files.autoSave" = "afterDelay";
                "git.autofetch" = true;
                "git.confirmSync" = false;
                "nix.enableLanguageServer" = true;
                "nix.serverPath" = "nil";
                "update.mode" = "none";
                "git.suggestSmartCommit" = false;
                "workbench.sideBar.location" = "right";
                "editor.renderWhitespace" = "none";
                "workbench.iconTheme" = "material-icon-theme";
                "editor.minimap.enabled" = false;
            });
        in [
            "f+ %h/.config/VSCodium/User/settings.json - - - - ${settings}"
            "f+ %h/.config/VSCodium/User/settings-default.json - - - - ${settings}"
        ];
    };
}
