{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.sprouted-portal;

  settings = {
    title = "Sprouted Cloud";
    subtitle = "Public services";
    documentTitle = "Sprouted Cloud";
    logo = "assets/branding.png";
    stylesheet = [ "assets/branding.css" ];
    footer = false;
    defaults.layout = "list";
    services = lib.singleton {
      items =
        allHosts
        |> lib.attrValues
        |> lib.concatMap (host: host.config.custom.meta.sites |> lib.attrValues)
        |> lib.filter (site: site.domain != cfg.domain)
        |> lib.filter (site: site.domain |> lib.hasSuffix ".sprouted.cloud")
        |> lib.filter (site: site.domain != "auth.sprouted.cloud")
        |> lib.sort (a: b: a.title < b.title)
        |> lib.map (site: {
          name = site.title;
          logo = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/${site.icon}.svg";
          inherit (site) url;
        });
    };
  };

  configFile = (pkgs.formats.yaml { }).generate "sprouted-portal-config.yml" settings;

  logo = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Seed_germination.png/330px-Seed_germination.png";
    hash = "sha256-TDqvIl4esKgvstAubbOfDE4YlpG0FHTPjVg4s0KnErk=";
  };

  stylesheet = pkgs.writeText "sprouted-portal.css" ''
    #bighead .first-line .logo img {
      width: 140px;
      max-width: none;
      max-height: 80px;
      padding: 5px 15px 5px 0;
    }
  '';
in
{
  options.custom.web-services.sprouted-portal = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    custom = {
      services.caddy.virtualHosts.${cfg.domain}.files =
        pkgs.runCommand "sprouted-portal-${cfg.domain}" { }
          ''
            cp -r ${pkgs.homer} "$out"
            chmod u+w "$out/assets"

            ln -s ${configFile} "$out/assets/config.yml"
            ln -s ${logo} "$out/assets/branding.png"
            ln -s ${stylesheet} "$out/assets/branding.css"
          '';

      meta.sites.${cfg.domain} = {
        title = "Sprouted Portal";
        icon = "homer";
      };
    };
  };
}
