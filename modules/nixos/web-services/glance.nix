{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;

  observabilityTitles = [
    "Alloy"
    "Prometheus"
    "Alertmanager"
  ];

  hosts = allHosts |> lib.attrValues;

  applicationSitesWidget =
    hosts
    |> lib.concatMap (host: host.config.custom.meta.sites |> lib.attrValues)
    |> lib.filter (service: !lib.elem service.title observabilityTitles)
    |> lib.groupBy (
      service:
      service.domain |> self.lib.isPrivateDomain |> (isPrivate: if isPrivate then "Private" else "Public")
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

  observabilitySitesWidget =
    hosts
    |> lib.map (host: {
      type = "monitor";
      cache = "1m";
      title = host.config.networking.hostName;
      sites =
        host.config.custom.meta.sites
        |> lib.attrValues
        |> lib.filter (service: lib.elem service.title observabilityTitles);
    })
    |> lib.filter ({ sites, ... }: sites != [ ])
    |> (widgets: {
      type = "split-column";
      max-columns = widgets |> lib.length;
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
                  autofocus = false;
                }
                applicationSitesWidget
                observabilitySitesWidget
              ];
            }
            {
              size = "small";
              widgets = [ githubBadgeWidget ];
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
