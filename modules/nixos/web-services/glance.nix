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

  bookmarksWidget = {
    type = "bookmarks";
    groups = [
      {
        links = [
          {
            title = "YouTube";
            url = "https://www.youtube.com/";
          }
          {
            title = "DeepL";
            url = "https://www.deepl.com/en/translator";
          }
          {
            title = "GitHub";
            url = "https://github.com/SebastianStork";
          }
          {
            title = "ChatGBT";
            url = "https://chatgpt.com/";
          }
        ];
      }
      {
        title = "Email";
        links = [
          {
            title = "Mailbox";
            url = "https://app.mailbox.org/appsuite/#!!&app=io.ox/mail&folder=default0/INBOX";
          }
          {
            title = "Proton";
            url = "https://mail.proton.me/u/1/inbox";
          }
          {
            title = "h_da";
            url = "https://webmail.stud.h-da.de/stud/?_task=mail&_mbox=INBOX";
          }
        ];
      }
      {
        title = "Nix";
        color = "200 50 50";
        links = [
          {
            title = "Wiki";
            url = "https://wiki.nixos.org/wiki/Main_Page";
          }
          {
            title = "NixOS Manual";
            url = "https://nixos.org/manual/nixos/stable/";
          }
          {
            title = "Packages Search";
            url = "https://search.nixos.org/packages";
          }
          {
            title = "NixOS Options Search";
            url = "https://search.nixos.org/options";
          }
          {
            title = "HM Options Search";
            url = "https://home-manager-options.extranix.com/";
          }
          {
            title = "Function Search";
            url = "https://noogle.dev/";
          }
          {
            title = "GitHub Code Search";
            url = "https://github.com/search?q=lang%3Anix%20&type=code";
          }
        ];
      }
      {
        title = "Infra";
        color = "140 70 50";
        links = [
          {
            title = "Backblaze";
            url = "https://secure.backblaze.com/b2_buckets.htm";
          }
          {
            title = "Healthchecks";
            url = "https://healthchecks.io/projects/ed5214d3-971f-4b66-997d-8ffd0d8cd4ca/checks/";
          }
          {
            title = "Hetzner";
            url = "https://console.hetzner.cloud/projects/10289618/servers";
          }
          {
            title = "Porkbun";
            url = "https://porkbun.com/";
          }
        ];
      }
      {
        title = "Uni";
        color = "10 70 50";
        links = [
          {
            title = "My";
            url = "https://my.h-da.de/";
          }
          {
            title = "Moodle";
            url = "https://lernen.h-da.de/";
          }
          {
            title = "GitLab";
            url = "https://code.fbi.h-da.de/";
          }
        ];
      }
    ];
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
                  autofocus = true;
                }
                applicationSitesWidget
                observabilitySitesWidget
              ];
            }
            {
              size = "small";
              widgets = [
                githubBadgeWidget
                bookmarksWidget
              ];
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
