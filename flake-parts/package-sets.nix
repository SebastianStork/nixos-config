{ inputs, ... }:
let
  nixpkgsConfig = {
    allowUnfree = true;
  };

  mkPkgs =
    nixpkgs: system:
    import nixpkgs {
      config = nixpkgsConfig;
      inherit system;
    };
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = mkPkgs inputs.nixpkgs system;
      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable system;
    in
    {
      _module.args = { inherit pkgs pkgs-unstable; };
    };
}
