{
  inputs,
  self,
  lib,
  ...
}:
let
  lib' = self.lib;

  mkHost =
    hostName:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self lib'; };
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

  hostNames = "${self}/hosts" |> lib'.listDirectoryNames;
in
{
  flake = {
    nixosConfigurations = hostNames |> lib'.genAttrs mkHost;

    deploy.nodes = hostNames |> lib'.genAttrs mkDeployNode;

    checks = inputs.deploy-rs.lib |> lib.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy);
  };
}
