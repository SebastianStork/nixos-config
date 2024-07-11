{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.sops = pkgs.mkShell {
        packages = [
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
        ];
      };
    };
}
