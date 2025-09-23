_: {
  perSystem =
    { inputs', pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.just
          pkgs.nh
          inputs'.deploy-rs.packages.default
        ];
      };
    };
}
