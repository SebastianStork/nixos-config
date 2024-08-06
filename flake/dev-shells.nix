{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.nh
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
