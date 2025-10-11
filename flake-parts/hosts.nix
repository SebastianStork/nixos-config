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
      modules = [
        { networking = { inherit hostName; }; }
        "${self}/hosts/common.nix"
        "${self}/hosts/${hostName}"
        "${self}/users/seb"
      ]
      ++ lib.optional (lib.pathExists "${self}/users/seb/@${hostName}") "${self}/users/seb/@${hostName}";
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
