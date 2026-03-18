{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;

  perHostDomains =
    perHostSitesWidget.widgets |> lib.concatMap (widget: widget.sites) |> lib.map (site: site.domain);

  perHostSitesWidget =
    allHosts
    |> lib.attrValues
    |> lib.map (host: {
      type = "monitor";
      cache = "1m";
      title = "${host.config.networking.hostName} Services";
      sites =
        host.config.custom.meta.sites
        |> lib.attrValues
        |> lib.filter (site: site.domain |> lib.hasSuffix host.config.custom.networking.overlay.fqdn);
    })
    |> lib.filter ({ sites, ... }: sites != [ ])
    |> (widgets: {
      type = "split-column";
      max-columns = widgets |> lib.length;
      inherit widgets;
    });

  applicationSitesWidget =
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
        sites = value;
      }
    )
    |> (widgets: {
      type = "split-column";
      max-columns = 2;
      inherit widgets;
    });

  githubWorkflowFiles =
    "${self}/.github/workflows"
    |> builtins.readDir
    |> lib.attrNames
    |> lib.filter (file: file |> lib.hasSuffix ".yml")
    |> lib.filter (file: file |> lib.hasPrefix "_" |> (hasPrefix: !hasPrefix));

  mkGithubWorkflowBadge =
    workflowFile:
    let
      workflowName = workflowFile |> lib.removeSuffix ".yml";
      workflowUrl = "https://github.com/SebastianStork/nixos-config/actions/workflows/${workflowFile}";
    in
    ''
      <a class="block" href="${workflowUrl}" target="_blank" rel="noopener noreferrer">
        <img
          class="block"
          src="${workflowUrl}/badge.svg"
          alt="${workflowName} workflow status"
        />
      </a>
    '';

  githubWorkflowBadges =
    githubWorkflowFiles |> lib.map mkGithubWorkflowBadge |> lib.concatStringsSep "\n";

  githubBadgeWidget = {
    type = "custom-api";
    title = "nixos-config";
    title-url = "https://github.com/SebastianStork/nixos-config";
    template = ''
      <div class="flex flex-col items-start gap-10">
        <div class="flex flex-wrap gap-10">
          ${githubWorkflowBadges}
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
              widgets = [
                {
                  type = "search";
                  search-engine = "https://search.splitleaf.de/search?q={QUERY}";
                  autofocus = true;
                }
                applicationSitesWidget
                perHostSitesWidget
              ];
            }
            {
              size = "small";
              widgets = [ githubBadgeWidget ] ++ dnsWidgets;
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
