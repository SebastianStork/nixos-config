{ config, lib, ... }:
{
  options.myConfig.sound.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.sound.enable {
    security.rtkit.enable = true;
    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        wireplumber.enable = true;
        pulse.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  };
}
