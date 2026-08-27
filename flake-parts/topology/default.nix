{
  inputs,
  self,
  lib,
  ...
}:
let
  classifyHost =
    _: host:
    let
      underlay = host.config.custom.networking.underlay;
    in
    if underlay.isPublic then
      "vps"
    else if underlay.isRoaming then
      "roaming"
    else
      "home";
in
{
  perSystem =
    { pkgs, ... }:
    let
      topologyPkgs = pkgs.extend inputs.topology.overlays.default;
      selfhstRevision = "948e3aa28d3110ee23957473a85431650e10e778";
      fetchSelfhstIcon =
        path: sha256:
        builtins.fetchurl {
          url = "https://raw.githubusercontent.com/selfhst/icons/${selfhstRevision}/${path}";
          inherit sha256;
        };
      hermesAgentResponse = builtins.fetchurl {
        url = "https://api.github.com/repos/selfhst/icons/contents/png/hermes-agent.png?ref=${selfhstRevision}";
        sha256 = "sha256-QEtYmJf/mLRoBkvvn9TNnVJdtPPFM0wj5fb/uaslVYA=";
      };
      hermesAgentBase64 =
        (builtins.fromJSON (builtins.readFile hermesAgentResponse)).content
        |> lib.replaceStrings [ "\n" ] [ "" ];
      icons = {
        android = fetchSelfhstIcon "svg/android.svg" "sha256-R8LFjMZ8czriBMEBNY9kT5MyivmGKQwny5cTLCZ5y+8=";
        garage = fetchSelfhstIcon "svg/garage.svg" "sha256-jmTj+yHgbAQ4ybMyMNEYJhwf6Efn/2S5ZFCP8MRyXGY=";
        hermesAgent = builtins.toFile "hermes-agent.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
            <image width="512" height="512" href="data:image/png;base64,${hermesAgentBase64}"/>
          </svg>
        '';
        syncthing = fetchSelfhstIcon "svg/syncthing.svg" "sha256-5dp4OhrkASKpuurKU0/doeY6IJS1sB8o+e+F8rEfjOY=";
      };
      topologyModule =
        { config, lib, ... }:
        let
          inherit (config.lib.topology)
            mkConnectionRev
            mkInternet
            mkRouter
            ;

          hosts = self.allHosts;
          placements = lib.mapAttrs classifyHost hosts;
          homeHosts = lib.filterAttrs (name: _: placements.${name} == "home") hosts;
          publicHosts = lib.filterAttrs (name: _: placements.${name} == "vps") hosts;

          firstHost = hosts |> lib.attrValues |> lib.head;
          overlayNetwork = firstHost.config.custom.networking.overlay;

          underlayInterfaceFor = host: host.config.custom.networking.underlay.interface;

          mkServices =
            groups:
            groups
            |> lib.filterAttrs (_: group: group.items != [ ])
            |> lib.mapAttrs (
              _: group: {
                inherit (group) name icon;
                info = lib.concatStringsSep ", " group.items;
              }
            );

          mkHostNode =
            name: host:
            let
              cfg = host.config;
              inherit (cfg) custom;
              net = custom.networking;
              placement = placements.${name};
              underlayInterface = underlayInterfaceFor host;
              isNixosHost = lib.hasAttr name self.nixosConfigurations;
              underlayAddress = if net.underlay.address == null then "DHCP" else net.underlay.address;

              sites = custom.meta.sites;
              enabledDomain = enabled: domain: lib.optional enabled domain;
              claimSiteDomains =
                domains:
                domains
                |> lib.filter (domain: domain != null && domain != "")
                |> lib.filter (domain: lib.hasAttr domain sites);
              siteTitles = domains: domains |> lib.map (domain: sites.${domain}.title) |> lib.unique;

              infrastructureSiteDomains = {
                monitoring = claimSiteDomains (
                  enabledDomain custom.services.prometheus.enable custom.services.prometheus.domain
                  ++ enabledDomain custom.services.alertmanager.enable custom.services.alertmanager.domain
                  ++ enabledDomain custom.web-services.grafana.enable custom.web-services.grafana.domain
                  ++ enabledDomain custom.web-services.scrutiny.enable custom.web-services.scrutiny.domain
                );
                dns = claimSiteDomains (
                  enabledDomain custom.services.blocking-nameserver.enable custom.services.blocking-nameserver.gui.domain
                );
                storage = claimSiteDomains (
                  enabledDomain custom.services.garage.enable custom.services.garage.admin.domain
                  ++ enabledDomain custom.services.s3-binary-cache.enable custom.services.s3-binary-cache.domain
                );
                syncthing = claimSiteDomains (
                  enabledDomain custom.services.syncthing.enable custom.services.syncthing.gui.domain
                );
                alloy = claimSiteDomains (enabledDomain custom.services.alloy.enable custom.services.alloy.domain);
              };

              claimedSiteDomains =
                infrastructureSiteDomains
                |> lib.attrValues
                |> lib.concatLists
                |> lib.unique;

              applicationSites = lib.removeAttrs sites claimedSiteDomains |> lib.attrValues;
              privateWebServices =
                applicationSites
                |> lib.filter (site: self.lib.isPrivateDomain site.domain)
                |> lib.map (site: site.title)
                |> lib.unique;
              publicWebServices =
                applicationSites
                |> lib.filter (site: !(self.lib.isPrivateDomain site.domain))
                |> lib.map (site: site.title)
                |> lib.unique;

              dns =
                lib.optional custom.services.blocking-nameserver.enable "Private blocking nameserver"
                ++ lib.optional custom.services.recursive-nameserver.enable "Private recursive nameserver"
                ++ lib.optional custom.services.public-nameserver.enable "Public authoritative nameserver";
              storage =
                siteTitles infrastructureSiteDomains.storage
                ++ lib.optional custom.services.file-share.enable "File share";
              automation =
                lib.optional custom.services.forgejo-runner.enable "Forgejo runner"
                ++ lib.optional custom.services.renovate.enable "Renovate";
              syncthing = lib.optional custom.services.syncthing.enable (
                if custom.services.syncthing.isServer then
                  "Synchronization server"
                else
                  "Client state synchronization"
              );
              nebulaRoles =
                lib.optional net.overlay.isLighthouse "Lighthouse"
                ++ lib.optional net.overlay.isLighthouse "Relay"
                ++ lib.optional net.overlay.isExitNode "Exit node";
              hermes = lib.optional (cfg.services.hermes-agent.enable or false) "Remote AI agent";

              services = mkServices {
                monitoring = {
                  name = "Monitoring";
                  icon = "services.prometheus";
                  items = siteTitles infrastructureSiteDomains.monitoring;
                };
                dns = {
                  name = "DNS";
                  icon = "services.adguardhome";
                  items = dns;
                };
                storage = {
                  name = "Storage";
                  icon = icons.garage;
                  items = storage;
                };
                syncthing = {
                  name = "Syncthing";
                  icon = icons.syncthing;
                  items = syncthing;
                };
                automation = {
                  name = "Automation";
                  icon = "services.forgejo";
                  items = automation;
                };
                private-web-services = {
                  name = "Private web-services";
                  icon = "services.glance";
                  items = privateWebServices;
                };
                public-web-services = {
                  name = "Public web-services";
                  icon = "services.glance";
                  items = publicWebServices;
                };
                nebula = {
                  name = "Nebula coordination";
                  icon = "services.wireguard";
                  items = nebulaRoles;
                };
                hermes = {
                  name = "Hermes agent";
                  icon = icons.hermesAgent;
                  items = hermes;
                };
              };
            in
            {
              inherit services;
              name = cfg.networking.hostName;
              deviceType = "nixos";
              deviceIcon = if isNixosHost then "devices.nixos" else icons.android;

              interfaces = {
                ${underlayInterface} = {
                  addresses = [ underlayAddress ];
                  gateways = lib.optional (net.underlay.gateway != null) net.underlay.gateway;
                  network = if placement == "home" then "home-lan" else "internet";
                  type = if net.underlay.wireless.enable || placement == "roaming" then "wifi" else "ethernet";
                };
                ${net.overlay.interface} = {
                  addresses = [ net.overlay.address ];
                  network = "nebula";
                  type = "tun";
                  virtual = true;
                };
              };
            };

          homePortNames = homeHosts |> lib.attrNames |> lib.map (name: "lan-${name}");

          homeRouter = mkRouter "router" {
            info = "TP-Link Archer C6 (192.168.0.1)";
            interfaceGroups = [
              homePortNames
              [ "wan" ]
            ];
            connections =
              homeHosts
              |> lib.mapAttrs' (
                name: host: lib.nameValuePair "lan-${name}" (mkConnectionRev name (underlayInterfaceFor host))
              );
            interfaces =
              lib.genAttrs homePortNames (port: {
                network = "home-lan";
                addresses = lib.optional (port == lib.head homePortNames) "192.168.0.1";
              })
              // {
                wan = {
                  network = "internet";
                  addresses = [ "IP REDACTED" ];
                };
              };
          };

          internetConnections = [
            (mkConnectionRev "home-router" "wan")
          ]
          ++ (
            publicHosts |> lib.mapAttrsToList (name: host: mkConnectionRev name (underlayInterfaceFor host))
          );
        in
        {
          networks = {
            internet = {
              name = "WAN";
              style = {
                primaryColor = "#f9a872";
                secondaryColor = null;
                pattern = "solid";
              };
            };
            home-lan = {
              name = "Home LAN";
              cidrv4 = "192.168.0.0/24";
              style = {
                primaryColor = "#78dba9";
                secondaryColor = null;
                pattern = "solid";
              };
            };
            nebula = {
              name = "Nebula P2P mesh";
              cidrv4 = overlayNetwork.networkCidr;
              style = {
                primaryColor = "#c68aee";
                secondaryColor = "#0d1117";
                pattern = "dashed";
              };
            };
          };

          nodes = lib.mapAttrs mkHostNode hosts // {
            internet = mkInternet { connections = internetConnections; };
            home-router = homeRouter;
          };
        };
      topologyConfig =
        (import inputs.topology {
          pkgs = topologyPkgs;
          modules = [ topologyModule ];
        }).config;
    in
    {
      packages.homelab-topology = import ./renderer.nix {
        inherit topologyConfig;
        topologySource = inputs.topology;
        pkgs = topologyPkgs;
        hostPlacements = lib.mapAttrs classifyHost self.allHosts;
      };
    };
}
