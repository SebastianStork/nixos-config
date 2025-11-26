{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
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
        pkgs-old = import inputs.nixpkgs-old {
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (config.nixpkgs) config;
        };
      in
      [ (pkgs-unstable.winboat.override { nodejs_24 = pkgs-old.nodejs_24; }) ];
  };
}
