{
  config,
  self,
  inputs,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.users.seb;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.custom.users.seb = {
    enable = lib.mkEnableOption "";
    zsh.enable = lib.mkEnableOption "";
    homeManager = {
      enable = lib.mkEnableOption "";
      configPath = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [
          "${self}/users/shared-home.nix"
          "${self}/users/seb/home.nix"
          "${self}/users/seb/@${config.networking.hostName}/home.nix"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sops.secrets."seb-password".neededForUsers = true;

        users.users.seb = {
          isNormalUser = true;
          description = "Sebastian Stork";
          hashedPasswordFile = config.sops.secrets."seb-password".path;
          extraGroups = [ "wheel" ];
          shell = lib.mkIf cfg.zsh.enable pkgs.zsh;
        };

        programs.zsh.enable = lib.mkIf cfg.zsh.enable true;
      }

      (lib.mkIf cfg.homeManager.enable {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs self pkgs-unstable;
          };

          users.seb.imports = cfg.homeManager.configPath;
        };
      })
    ]
  );
}
