{ self, inputs, ... }:
{
  flake.lib' = import "${self}/lib" inputs.nixpkgs.lib;
}
