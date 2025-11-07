{ self, inputs, ... }:
{
  flake.lib = import "${self}/lib" {
    inherit (inputs.nixpkgs) lib;
    inherit self;
  };
}
