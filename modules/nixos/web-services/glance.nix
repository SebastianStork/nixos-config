{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;

  perHostSitesWidget =
    let
      widgets =
        allHosts
        |> lib.attrValues
        |> lib.map (host: {
          type = "monitor";
          cache = "1m";
          title = "${host.config.networking.hostName} Services";
          style = "compact";
          sites =
            host.config.custom.meta.sites
            |> lib.attrValues
            |> lib.filter (site: site.domain |> lib.hasSuffix host.config.custom.networking.overlay.fqdn)
            |> lib.sort (a: b: a.title < b.title);
        })
        |> lib.filter ({ sites, ... }: sites != [ ]);
    in
    {
      type = "split-column";
      max-columns = widgets |> lib.length;
      inherit widgets;
    };

  perHostDomains =
    perHostSitesWidget.widgets |> lib.concatMap (widget: widget.sites) |> lib.map (site: site.domain);

  applicationSitesWidgets =
    allHosts
    |> lib.attrValues
    |> lib.concatMap (host: host.config.custom.meta.sites |> lib.attrValues)
    |> lib.filter (site: !lib.elem site.domain perHostDomains)
    |> lib.groupBy (
      site:
      site.domain |> self.lib.isPrivateDomain |> (isPrivate: if isPrivate then "Private" else "Public")
    )
    |> lib.mapAttrsToList (
      name: value: {
        type = "monitor";
        cache = "1m";
        title = "${name} Services";
        sites = value |> lib.sort (a: b: a.title < b.title);
      }
    );

  nixosRepoUrl = "https://codeberg.org/SebastianStork/nixos-config";

  workflowFiles =
    "${self}/.forgejo/workflows"
    |> lib.readDir
    |> lib.attrNames
    |> lib.filter (file: file |> lib.hasSuffix ".yml")
    |> lib.filter (file: !(file |> lib.hasPrefix "_"));

  mkWorkflowBadge =
    workflowFile:
    let
      workflowName = workflowFile |> lib.removeSuffix ".yml";
      workflowBadge = "${nixosRepoUrl}/badges/workflows/${workflowFile}/badge.svg?label=${workflowName}";
      workflowLink = "${nixosRepoUrl}/actions?workflow=${workflowFile}";
    in
    ''
      <a class="block" href="${workflowLink}" target="_blank" rel="noopener noreferrer">
        <img
          class="block"
          src="${workflowBadge}"
          alt="${workflowName} workflow status"
        />
      </a>
    '';

  workflowBadges = workflowFiles |> lib.map mkWorkflowBadge |> lib.concatStringsSep "\n";

  codebergBadgeWidget = {
    type = "custom-api";
    title = "nixos-config";
    title-url = nixosRepoUrl;
    template = ''
      <div class="flex flex-col items-start gap-10">
        <div class="flex flex-wrap gap-10">
          ${workflowBadges}
        </div>
      </div>
    '';
  };

  dnsWidgets =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.blocking-nameserver.enable)
    |> lib.map (host: {
      type = "dns-stats";
      title = host.config.networking.hostName;
      service = "adguard";
      url = "https://${host.config.custom.services.blocking-nameserver.gui.domain}/";
    });
in
{
  options.custom.web-services.glance = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 63958;
    };
  };

  config = lib.mkIf cfg.enable {
    services.glance = {
      enable = true;

      settings = {
        server.port = cfg.port;

        pages = lib.singleton {
          name = "Home";
          center-vertically = true;

          columns = [
            {
              size = "full";
              widgets =
                lib.singleton {
                  type = "search";
                  search-engine = "https://search.splitleaf.de/search?q={QUERY}";
                  autofocus = true;
                }
                ++ applicationSitesWidgets
                ++ lib.singleton perHostSitesWidget;
            }
            {
              size = "small";
              widgets = [ codebergBadgeWidget ] ++ dnsWidgets;
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
