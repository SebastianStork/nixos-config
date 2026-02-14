{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.networking.overlay;
in
{
  options.custom.networking.overlay = {
    networkCidr = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    networkAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = cfg.networkCidr |> lib.splitString "/" |> lib.head;
      readOnly = true;
    };
    prefixLength = lib.mkOption {
      type = lib.types.ints.between 0 32;
      default = cfg.networkCidr |> lib.splitString "/" |> lib.last |> lib.toInt;
      readOnly = true;
    };
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };

    address = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    cidr = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "${cfg.address}/${toString cfg.prefixLength}";
      readOnly = true;
    };
    interface = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    systemdUnit = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };

    isLighthouse = lib.mkEnableOption "";
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
    };

    dnsServers = lib.mkOption {
      type = lib.types.anything;
      default =
        allHosts
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.services.dns.enable)
        |> lib.map (host: host.config.custom.networking.overlay.address);
    };

    implementation = lib.mkOption {
      type = lib.types.enum [ "nebula" ];
      default = "nebula";
    };
  };
}
