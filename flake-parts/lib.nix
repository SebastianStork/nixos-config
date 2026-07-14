{ self, lib, ... }:
{
  flake.lib = {
    concatWords = words: words |> lib.concatStringsSep " ";

    headOrNull = list: if list == [ ] then null else list |> lib.head;

    isPrivateDomain = domain: domain |> lib.hasSuffix ".splitleaf.de";

    listNixFilesRecursively =
      dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

    listDirectoryNames =
      path:
      path
      |> lib.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.attrNames;

    genAttrs = f: names: lib.genAttrs names f;

    genAttrs' = f: names: lib.genAttrs' names f;

    mkInvalidConfigMessage = subject: reason: "Invalid configuration for ${subject}: ${reason}.";

    mkUnprotectedMessage =
      name:
      self.lib.mkInvalidConfigMessage name "the service must use a private domain until access control is configured";

    relativePath = path: path |> lib.toString |> lib.removePrefix "${self}/";

    isolateStorePath =
      path:
      if path |> lib.hasPrefix "${self}/" then
        builtins.path {
          inherit path;
          name = path |> lib.removePrefix "${self}/" |> lib.strings.sanitizeDerivationName;
        }
      else
        path;

    nebulaHostInventory =
      host:
      let
        inherit (host.config.custom.services) nebula;
        netCfg = host.config.custom.networking;
      in
      {
        name = netCfg.hostName;
        certificate = lib.toString nebula.certificateFile;
        certificateOutput = self.lib.relativePath nebula.certificateFile;
        publicKey = lib.toString nebula.publicKeyFile;
        ca = lib.toString nebula.caCertificateFile;
        networks = [ netCfg.overlay.cidr ];
        inherit (nebula) unsafeNetworks groups;
      };

    types.existingPath = (lib.types.addCheck lib.types.path lib.pathExists) // {
      description = "path that exists";
    };
  };
}
