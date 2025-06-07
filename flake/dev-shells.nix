{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.nh
            inputs.deploy-rs.packages.${system}.default
          ];
        };

        sops = pkgs.mkShell {
          packages = [
            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age
          ];
        };
      };
    };
}
