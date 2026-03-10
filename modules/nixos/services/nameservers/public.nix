{
  config,
  inputs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.public-nameserver;
  netCfg = config.custom.networking;

  zoneData =
    zone:
    let
      mkSubdomain =
        { name, address }:
        {
          inherit name;
          value.A = [ address ];
        };

      serviceRecords =
        allHosts
        |> lib.attrValues
        |> lib.concatMap (
          host:
          host.config.custom.services.caddy.virtualHosts
          |> lib.attrValues
          |> lib.map (vHost: vHost.domain)
          |> lib.filter (domain: domain |> lib.hasSuffix "${zone}")
          |> lib.map (domain: domain |> lib.removeSuffix ".${zone}" |> lib.removeSuffix "${zone}") # In case the domain is the root domain
          |> lib.map (name: {
            inherit name;
            inherit (host.config.custom.networking.underlay) address;
          })
        );

      nsRecords =
        allHosts
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.services.public-nameserver.enable)
        |> lib.map (host: {
          name = host.config.custom.services.public-nameserver.publicHostName;
          inherit (host.config.custom.networking.underlay) address;
        });
    in
    inputs.dns.lib.toString zone {
      SOA = {
        nameServer =
          nsRecords
          |> lib.map (record: record.name)
          |> lib.naturalSort
          |> lib.head
          |> (hostName: "${hostName}.${zone}.");
        adminEmail = "hostmaster@sstork.dev";
        serial = 1;
      };

      NS = nsRecords |> lib.map ({ name, ... }: "${name}.${zone}.");

      A = serviceRecords |> lib.filter ({ name, ... }: name == "") |> lib.map (record: record.address);

      subdomains =
        serviceRecords
        |> lib.filter ({ name, ... }: name != "")
        |> (subRecords: nsRecords ++ subRecords)
        |> lib.map mkSubdomain
        |> lib.listToAttrs;
    };
in
{
  options.custom.services.public-nameserver = {
    enable = lib.mkEnableOption "";
    publicHostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = netCfg.hostName;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 53;
    };
    zones = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.nsd = {
      enable = true;
      interfaces = [ "${netCfg.underlay.address}@${toString cfg.port}" ];
      zones =
        cfg.zones
        |> lib.map (zone: {
          name = zone;
          value.data = zoneData zone;
        })
        |> lib.listToAttrs;
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
