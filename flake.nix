{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapper-manager = {
      url = "github:nrabulinski/wrapper-manager/wrap-certain-programs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        north = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self inputs;
          };
          modules = [
            ./hosts/north
            "${./.}/users/seb/@north.nix"
          ];
        };
        inspiron = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self inputs;
          };
          modules = [
            ./hosts/inspiron
            "${./.}/users/seb/@inspiron.nix"
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.sops ]; };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
