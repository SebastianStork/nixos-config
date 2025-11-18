{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.winboat.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.winboat.enable {
    virtualisation.docker.enable = true;
    users.users.seb.extraGroups = [ config.users.groups.docker.name ];

    environment.systemPackages =
      let
        pkgs-c5ae371 = import inputs.nixpkgs-c5ae371 {
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (config.nixpkgs) config;
        };
      in
      [ pkgs-c5ae371.winboat ];
  };
}
