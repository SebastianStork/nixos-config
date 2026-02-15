{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.comin.nixosModules.comin ];

  options.custom.services.comin.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.comin.enable {
    services.comin = {
      enable = true;
      remotes = lib.singleton {
        name = "origin";
        url = "https://github.com/SebastianStork/nixos-config.git";
        branches.main.name = "deploy";
      };
    };
  };
}
