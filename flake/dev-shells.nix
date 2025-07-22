{ inputs, self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.nh
            inputs.deploy-rs.packages.${system}.default
          ];
        };

        sops = pkgs.mkShell {
          SOPS_CONFIG = self.packages.${system}.sops-config;
          packages = [
            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age
          ];
        };
      };
    };
}
