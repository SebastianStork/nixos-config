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

  mkDeployNode = hostName: {
    hostname = "${hostName}.${
      self.nixosConfigurations.${hostName}.config.custom.networking.overlay.domain
    }";
    user = "root";
    interactiveSudo = true;
    profiles.system.path =
      inputs.deploy-rs.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations.${hostName};
  };

  hostNames = "${self}/hosts" |> self.lib.listDirectoryNames;
in
{
  flake = {
    nixosConfigurations = hostNames |> self.lib.genAttrs mkHost;

    deploy.nodes = hostNames |> self.lib.genAttrs mkDeployNode;

    checks = inputs.deploy-rs.lib |> lib.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy);
  };
}
