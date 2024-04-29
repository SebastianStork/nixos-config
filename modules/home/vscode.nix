{
    inputs,
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

            package = pkgs.vscode-with-extensions.override {
                vscode = pkgs.vscodium;
                vscodeExtensions = let
                    ext = inputs.nix-vscode-extensions.extensions.${pkgs.system};
                in [
                    ext.open-vsx.jnoortheen.nix-ide
                    ext.open-vsx.pkief.material-icon-theme
                    ext.open-vsx.yzhang.markdown-all-in-one
                ];
            };
        };

        systemd.user.tmpfiles.rules = let
            settings = builtins.replaceStrings [","] [",\\n"] (builtins.toJSON {
                "workbench.colorTheme" =
                    {
                        dark = "Default Dark Modern";
                        light = "Default Light Modern";
                    }
                    ."${config.myConfig.de.theme}";
                "workbench.iconTheme" = "material-icon-theme";
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
                "editor.minimap.enabled" = false;
            });
        in [
            "f+ %h/.config/VSCodium/User/settings.json - - - - ${settings}"
            "f+ %h/.config/VSCodium/User/settings-default.json - - - - ${settings}"
        ];
    };
}
