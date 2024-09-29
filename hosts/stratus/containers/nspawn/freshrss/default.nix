{ lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "rss";
in
{
  sops.secrets."container/freshrss/admin-password" = { };

  containers.${serviceName}.config =
    {
      config,
      domain,
      dataDir,
      ...
    }:
    let
      userName = config.users.users.freshrss.name;
      groupName = config.users.groups.freshrss.name;
    in
    {
      systemd.tmpfiles.rules = [
        "z /run/secrets/container/freshrss/admin-password - ${userName} ${groupName} -"
      ];

      services.freshrss = {
        enable = true;
        inherit dataDir;
        baseUrl = "https://${subdomain}.${domain}";
        defaultUser = "seb";
        passwordFile = "/run/secrets/container/freshrss/admin-password";
      };

      myConfig.tailscale = {
        inherit subdomain;
        serve = "80";
      };
    };
}
