{ moduleArgs, ... }:
let
  inherit (moduleArgs) lib inputs;

  extension = shortId: uuid: {
    name = uuid;
    value = {
      install_url = "file:///${
        inputs.firefox-addons.packages.x86_64-linux.${shortId}
      }/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${uuid}.xpi";
      installation_mode = "force_installed";
      default_area = "menupanel";
    };
  };
in
{
  "*".installation_mode = "blocked";
}
// lib.listToAttrs [
  (extension "dictionary-german" "de-DE@dictionaries.addons.mozilla.org")
  (extension "ublock-origin" "uBlock0@raymondhill.net")
  (extension "bitwarden" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
  (extension "return-youtube-dislikes" "{762f9885-5a13-4abd-9c77-433dcd38b8fd}")
  (extension "sponsorblock" "sponsorBlocker@ajay.app")
  (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
]
