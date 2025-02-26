{ lib, ... }:
{
  options.myConfig.hibernation.enable = lib.mkEnableOption "";
}
