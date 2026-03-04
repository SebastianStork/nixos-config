{
  config,
  inputs,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.recursive-nameserver;
  netCfg = config.custom.networking;

  blocklist =
    pkgs.runCommand "blocklist.conf" { } ''
      echo "server:" > $out
      cat ${inputs.blocklist}/hosts \
        | grep '^0.0.0.0 ' \
        | awk '$2 != "0.0.0.0" {print "  local-zone: \"" $2 "\" refuse"}' \
        >> $out
    ''
    |> toString;

  privateNameservers =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.private-nameserver.enable);
in
{
  options.custom.services.recursive-nameserver = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 53;
    };
    blockAds = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services = {
          unbound = {
            enable = true;
            settings = {
              server = {
                interface = [ "${netCfg.overlay.address}@${toString cfg.port}" ];
                access-control = [ "${toString netCfg.overlay.networkCidr} allow" ];
                prefetch = true;
              };
              include-toplevel = lib.mkIf cfg.blockAds blocklist;
            };
          };

          nebula.networks.mesh.firewall.inbound = lib.singleton {
            inherit (cfg) port;
            proto = "any";
            host = "any";
          };
        };

        systemd.services.unbound = {
          requires = [ netCfg.overlay.systemdUnit ];
          after = [ netCfg.overlay.systemdUnit ];
        };
      }

      (lib.mkIf (privateNameservers != [ ]) {
        services.unbound.settings = {
          server = {
            local-zone = ''"${netCfg.overlay.domain}." nodefault'';
            domain-insecure = netCfg.overlay.domain;
          };

          stub-zone = lib.singleton {
            name = netCfg.overlay.domain;
            stub-addr =
              privateNameservers
              |> lib.map (
                host:
                "${host.config.custom.networking.overlay.address}@${toString host.config.custom.services.private-nameserver.port}"
              );
          };
        };
      })
    ]
  );
}
