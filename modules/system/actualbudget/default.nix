{
  config,
  inputs,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.myConfig.actualbudget;
in
{
  disabledModules = [ "services/web-apps/actual.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/actual.nix" ];

  options.myConfig.actualbudget = {
    enable = lib.mkEnableOption "";
    subdomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.actual = { };
    users.users.actual = {
      isSystemUser = true;
      group = "actual";
    };

    services.actual = {
      enable = true;
      package = pkgs-unstable.actual-server;

      settings = {
        hostname = "localhost";
        inherit (cfg) port;
      };
    };
  };
}
