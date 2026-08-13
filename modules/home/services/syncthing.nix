{ lib, ... }:
{
  options.custom.services.syncthing.folders = lib.mkOption {
    type = lib.types.listOf lib.types.nonEmptyStr;
    default = [ ];
  };
}
