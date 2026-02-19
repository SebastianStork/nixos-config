{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.programs.firefox;

  mkExtension =
    {
      name,
      uuid,
      defaultArea,
      ...
    }:
    {
      name = uuid;
      value = {
        install_url = "file:///${
          inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}.${name}
        }/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${uuid}.xpi";
        installation_mode = "force_installed";
        default_area = defaultArea;
      };
    };
in
{
  options.custom.programs.firefox = {
    enable = lib.mkEnableOption "";
    extensions = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "" // {
                default = true;
              };
              name = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = name;
              };
              uuid = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "";
              };
              defaultArea = lib.mkOption {
                type = lib.types.enum [
                  "menupanel"
                  "navbar"
                ];
                default = "menupanel";
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    custom.programs.firefox.extensions = {
      dictionary-german.uuid = "de-DE@dictionaries.addons.mozilla.org";
      ublock-origin.uuid = "uBlock0@raymondhill.net";
      bitwarden.uuid = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      return-youtube-dislikes.uuid = "{762f9885-5a13-4abd-9c77-433dcd38b8fd}";
      sponsorblock.uuid = "sponsorBlocker@ajay.app";
      clearurls.uuid = "{74145f27-f039-47ce-a470-a662b129930a}";
      karakeep = {
        uuid = "addon@karakeep.app";
        defaultArea = "navbar";
      };
    };

    programs.firefox = {
      enable = true;

      profiles.default = {
        settings =
          let
            uiState = ''{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["sponsorblocker_ajay_app-browser-action","_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","_74145f27-f039-47ce-a470-a662b129930a_-browser-action","ublock0_raymondhill_net-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","customizableui-special-spring1","urlbar-container","customizableui-special-spring2","save-to-pocket-button","downloads-button","fxa-toolbar-menu-button","unified-extensions-button","sidebar-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["firefox-view-button","tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["personal-bookmarks"]},"seen":["developer-button","sponsorblocker_ajay_app-browser-action","_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","_74145f27-f039-47ce-a470-a662b129930a_-browser-action","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","unified-extensions-area","PersonalToolbar","TabsToolbar","toolbar-menubar"],"currentVersion":20,"newElementCount":5}'';
          in
          {
            "intl.accept_languages" = "en-us,en,de-de,de";
            "browser.uiCustomization.state" = uiState;
            "sidebar.position_start" = false;
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.bookmarks.file" = "";
            "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
            "general.autoScroll" = true;
            "middlemouse.paste" = false;
            "signon.rememberSignons" = false;
            "extensions.formautofill.creditCards.enabled" = false;
            "browser.tabs.loadBookmarksInBackground" = true;
            "browser.tabs.groups.enabled" = true;
            "browser.uidensity" = 1;
            "sidebar.revamp" = false;
            "media.eme.enabled" = true;
          };

        extraConfig = lib.readFile "${inputs.betterfox}/user.js";
      };

      policies.ExtensionSettings =
        (
          cfg.extensions
          |> lib.attrValues
          |> lib.filter ({ enable, ... }: enable)
          |> lib.map mkExtension
          |> lib.listToAttrs
        )
        // {
          "*".installation_mode = "blocked";
        };
    };
  };
}
