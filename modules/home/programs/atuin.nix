{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.atuin.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.atuin.enable {
    programs.atuin = {
      enable = true;
      forceOverwriteSettings = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        sync_address = "https://atuin.${osConfig.custom.networking.overlay.domain}";
        key_path = pkgs.writeText "atuin-key" "3AAgzNnMicyALmrMt8ywzL/Mv3LMkEI/zKdPzLDMwCB9KCAwWsybzOrMn8zmzLZszIgMMQ==\n";
      };
    };
  };
}
