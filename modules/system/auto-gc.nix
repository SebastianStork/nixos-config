{
  config,
  lib,
  ...
}: {
  options.myConfig.auto-gc.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.auto-gc.enable {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
