{
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."40-eno1" = {
      matchConfig.Name = "eno1";
      networkConfig.DHCP = "yes";
    };
  };

  imports = [
    ./nextcloud
    ./paperless
  ];
}
