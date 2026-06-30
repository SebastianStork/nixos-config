{
  config,
  self,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  mkMount =
    { what, where }:
    {
      name = where |> lib.removePrefix "/" |> lib.replaceString "/" "-";
      value = {
        Install.WantedBy = [ "default.target" ];
        Unit = {
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };
        Mount = {
          Type = "fuse.sshfs";
          What = what;
          Where = where;
          Options = "_netdev,user,delay_connect,reconnect,ServerAliveInterval=15,dir_cache=yes,idmap=user,follow_symlinks,transform_symlinks,compression=yes";
        };
      };
    };
in
{
  home.packages =
    let
      hasFileShare =
        allHosts |> lib.attrValues |> lib.any (host: host.config.custom.services.file-share.enable);
    in
    lib.optional hasFileShare pkgs.sshfs;

  systemd.user.mounts =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.file-share.enable)
    |> lib.map (host: host.config.networking.hostName)
    |> (
      hostNames:
      if lib.length hostNames == 1 then
        lib.singleton {
          what = "${lib.head hostNames}:/home/seb/share";
          where = "${config.home.homeDirectory}/Share";
        }
      else
        hostNames
        |> lib.map (hostName: {
          what = "${hostName}:/home/seb/share";
          where = "${config.home.homeDirectory}/Share/${hostName}";
        })
    )
    |> self.lib.genAttrs' mkMount;
}
