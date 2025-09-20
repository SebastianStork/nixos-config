{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost =
    hostName:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules =
        let
          hostFiles =
            "${self}/hosts/${hostName}"
            |> lib.filesystem.listFilesRecursive
            |> lib.filter (lib.hasSuffix ".nix");

          userFiles =
            "${self}/users"
            |> builtins.readDir
            |> lib.filterAttrs (_: type: type == "directory")
            |> lib.attrNames
            |> map (user: "${self}/users/${user}/@${hostName}")
            |> lib.filter (path: lib.pathExists path);
        in
        [
          { networking = { inherit hostName; }; }
          "${self}/hosts/common.nix"
        ]
        ++ hostFiles
        ++ userFiles;
    };

  mkDeployNode = hostname: {
    inherit hostname;
    sshUser = "root";
    profiles.system.path =
      inputs.deploy-rs.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations.${hostname};
  };
in
{
  flake = {
    nixosConfigurations =
      "${self}/hosts"
      |> builtins.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.mapAttrs (name: _: mkHost name);

    deploy.nodes =
      "${self}/hosts"
      |> builtins.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.mapAttrs (name: _: mkDeployNode name);

    checks = lib.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
