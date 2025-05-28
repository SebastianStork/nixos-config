{ config, lib, ... }:
{
  options.custom.sound.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.sound.enable {
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
