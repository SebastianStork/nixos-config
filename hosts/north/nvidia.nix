{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  systemd.services.gpu-temp-reader = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "fancontrol.service" ];
    before = [ "fancontrol.service" ];
    script = ''
      ${lib.getExe' pkgs.coreutils "touch"} /tmp/nvidia-gpu-temp
      while :; do
        temp="$(${lib.getExe' config.hardware.nvidia.package "nvidia-smi"} --query-gpu=temperature.gpu --format=csv,noheader,nounits)"
        ${lib.getExe' pkgs.coreutils "echo"} "$((temp * 1000))" > /tmp/nvidia-gpu-temp
        ${lib.getExe' pkgs.coreutils "sleep"} 2
      done
    '';
  };
}
