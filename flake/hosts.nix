{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost = hostName: {
    ${hostName} = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules =
        let
          hostFiles =
            "${self}/hosts/${hostName}"
            |> lib.filesystem.listFilesRecursive
            |> builtins.filter (lib.hasSuffix ".nix");
          userFiles =
            "${self}/users"
            |> builtins.readDir
            |> lib.filterAttrs (_: type: type == "directory")
            |> builtins.attrNames
            |> map (user: "${self}/users/${user}/@${hostName}")
            |> builtins.filter (path: builtins.pathExists path);
        in
        lib.flatten [
          { networking = { inherit hostName; }; }
          "${self}/hosts/shared.nix"
          hostFiles
          userFiles
        ];
    };
  };

  mkDeployNode = hostName: {
    ${hostName} = {
      hostname = hostName;
      sshUser = "root";
      remoteBuild = true;
      profiles.system.path =
        inputs.deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.${hostName};
    };
  };
in
{
  flake = {
    nixosConfigurations =
      "${self}/hosts"
      |> builtins.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.concatMapAttrs (name: _: mkHost name);

    deploy.nodes =
      "${self}/hosts"
      |> builtins.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.concatMapAttrs (name: _: mkDeployNode name);
  };
}
