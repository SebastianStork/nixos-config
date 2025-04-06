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
          "${self}/hosts/${hostName}"
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
      (mkHost "stratus")
    ];

    deploy.nodes = {
      stratus = {
        hostname = "stratus";
        sshUser = "root";
        profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.stratus;
      };
      alto = {
        hostname = "alto";
        sshUser = "root";
        profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.alto;
      };
    };
  };
}
