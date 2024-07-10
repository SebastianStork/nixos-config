{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapper-manager = {
      #! Wrapper-manager fork with selective binary wrapping
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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
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
            "${self}/users/seb/@north"
          ];
        };
        inspiron = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self inputs;
          };
          modules = [
            ./hosts/inspiron
            "${self}/users/seb/@inspiron"
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.sops ]; };

      formatter.${system} =
        (inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt-rfc-style.enable = true;
        }).config.build.wrapper;
    };
}
