{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.wireshark.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.wireshark.enable {
    programs.wireshark.enable = true;
    environment.systemPackages = [ pkgs.wireshark ];
    users.users.seb.extraGroups = [ "wireshark" ];
  };
}
