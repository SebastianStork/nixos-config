{ inputs, lib, ... }:
let
  nixpkgsConfig = {
    allowUnfree = true;
    permittedInsecurePackages = [ "pnpm-9.15.9" ];
  };

  mkPkgs =
    nixpkgs: system:
    import nixpkgs {
      config = nixpkgsConfig;
      inherit system;
    };

  mkRegistryFlake =
    pkgs: nixpkgs:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    pkgs.writeTextDir "flake.nix" ''
      {
        outputs = { self }:
          let
            nixpkgs = builtins.getFlake "path:${nixpkgs.outPath}?narHash=${nixpkgs.narHash}";
          in
          {
            legacyPackages."${system}" = import nixpkgs.outPath {
              system = "${system}";
              config = ${lib.generators.toPretty { } nixpkgsConfig};
            };
          };
      }
    '';
in
{
  flake.nixosModules.pkgs-registry =
    { pkgs, ... }:
    {
      nix = {
        registry = {
          pkgs.to = {
            type = "path";
            path = mkRegistryFlake pkgs inputs.nixpkgs;
          };
          pkgs-unstable.to = {
            type = "path";
            path = mkRegistryFlake pkgs inputs.nixpkgs-unstable;
          };
        };
        nixPath = [
          "pkgs=flake:pkgs"
          "pkgs-unstable=flake:pkgs-unstable"
        ];
      };
    };

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
