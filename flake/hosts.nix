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
            |> builtins.readDir
            |> lib.filterAttrs (fileName: type: (fileName |> lib.hasSuffix ".nix") && type == "regular")
            |> builtins.attrNames
            |> map (fileName: "${self}/hosts/${hostName}/${fileName}");
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
in
{
  flake = {
    nixosConfigurations = lib.mkMerge [
      (mkHost "alto")
      (mkHost "fern")
      (mkHost "north")
    ];

    deploy.nodes = {
      alto = {
        hostname = "alto";
        sshUser = "root";
        profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.alto;
      };
    };
  };
}
