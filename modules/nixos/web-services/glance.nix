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

  applicationSites =
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
    })
    |> lib.singleton;

  observabilitySites =
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
    })
    |> lib.singleton;
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
                ++ applicationSites
                ++ observabilitySites;
            }
            {
              size = "small";
              widgets = lib.singleton {
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
                        url = "https://home-manager-options.extranix.com/";
                      }
                      {
                        title = "NixOS Manual";
                        url = "https://nixos.org/manual/nixos/stable/";
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
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
