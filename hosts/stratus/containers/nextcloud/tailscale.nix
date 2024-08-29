{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    useRoutingFeatures = "server";
    interfaceName = "userspace-networking";
    extraUpFlags = [ "--ssh" ];
  };

  systemd.services.nextcloud-serve = {
    after = [
      "tailscaled.service"
      "tailscaled-autoconnect.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${lib.getExe pkgs.tailscale} cert ${config.networking.fqdn}
      ${lib.getExe pkgs.tailscale} serve reset
      ${lib.getExe pkgs.tailscale} serve --bg 80
    '';
  };
}
