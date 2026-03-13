{ self, lib, ... }:
{
  flake.lib = {
    isPrivateDomain = domain: domain |> lib.hasSuffix ".splitleaf.de";

    listNixFilesRecursively =
      dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

    listDirectoryNames =
      path: path |> builtins.readDir |> lib.filterAttrs (_: type: type == "directory") |> lib.attrNames;

    genAttrs = f: names: lib.genAttrs names f;

    mkInvalidConfigMessage = subject: reason: "Invalid configuration for ${subject}: ${reason}.";

    mkUnprotectedMessage =
      name:
      self.lib.mkInvalidConfigMessage name "the service must use a private domain until access control is configured";

    relativePath = path: path |> toString |> lib.removePrefix "${self}/";

    types.existingPath = (lib.types.addCheck lib.types.path lib.pathExists) // {
      description = "path that exists";
    };
  };
}
