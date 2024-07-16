{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = (import ./treefmt.nix { inherit inputs pkgs; }).wrapper;
    };
}
