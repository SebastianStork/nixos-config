{ config, lib, ... }:
{
  options.myConfig.vpn.lgs.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.vpn.lgs.enable {
    sops.secrets = {
      "vpn/lgs/crt" = { };
      "vpn/lgs/key" = { };
    };

    services.openvpn.servers.lgs = {
      autoStart = false;

      config = ''
        dev tap
        persist-tun
        persist-key
        data-ciphers AES-128-GCM:AES-256-CBC
        data-ciphers-fallback AES-256-CBC
        auth SHA1
        tls-client
        client
        resolv-retry infinite
        remote 194.9.190.11 1194 udp4
        nobind
        auth-user-pass
        ca ${config.sops.secrets."vpn/lgs/crt".path}
        tls-auth ${config.sops.secrets."vpn/lgs/key".path} 1
        remote-cert-tls server
        explicit-exit-notify
      '';
    };
  };
}
