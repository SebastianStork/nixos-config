{ self, lib, ... }:
{
  flake.lib = {
    concatWords = words: words |> lib.concatStringsSep " ";

    headOrNull = list: if list == [ ] then null else list |> lib.head;

    exactlyOne =
      description: values:
      if lib.length values == 1 then
        lib.head values
      else
        throw "Expected exactly one ${description}, found ${values |> lib.length |> lib.toString}";

    atMostOne =
      description: values:
      if lib.length values <= 1 then
        self.lib.headOrNull values
      else
        throw "Expected at most one ${description}, found ${values |> lib.length |> lib.toString}";

    uncheckedHostConfig =
      host:
      (host.extendModules {
        modules = [ { _module.check = false; } ];
      }).config;

    privateDomain = "splitleaf.de";

    isPrivateDomain = domain: domain |> lib.hasSuffix ".${self.lib.privateDomain}";

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
        overlay = host.config.custom.networking.overlay;
        inherit (overlay) nebula;
      in
      {
        name = host.config.networking.hostName;
        certificate = lib.toString nebula.certificateFile;
        certificateOutput = self.lib.relativePath nebula.certificateFile;
        publicKey = lib.toString nebula.publicKeyFile;
        ca = lib.toString nebula.caCertificateFile;
        networks = [ overlay.cidr ];
        inherit (nebula) unsafeNetworks;
        groups = overlay.accessGroups;
      };

    types.existingPath = (lib.types.addCheck lib.types.path lib.pathExists) // {
      description = "path that exists";
    };
  };
}
