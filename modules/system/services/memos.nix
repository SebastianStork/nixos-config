{
  config,
  options,
  modulesPath,
  inputs,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.memos;
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/memos.nix" ];

  options.custom.services.memos = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5230;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (lib.pathExists "${modulesPath}/services/misc/memos.nix") "TODO: Use memos module from stable nixpkgs";

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.memos = {
      enable = true;
      package = pkgs-unstable.memos;
      settings = options.services.memos.settings.default // {
        MEMOS_PORT = builtins.toString cfg.port;
        MEMOS_INSTANCE_URL = "https://${cfg.domain}";
      };
    };
  };
}
