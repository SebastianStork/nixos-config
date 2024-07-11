{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapper-manager = {
      # Wrapper-manager fork with selective binary wrapping
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
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = {
        nixosConfigurations = {
          north = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit (inputs) self;
              inherit inputs;
            };
            modules = [
              ./hosts/north
              "${inputs.self}/users/seb/@north"
            ];
          };
          inspiron = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit (inputs) self;
              inherit inputs;
            };
            modules = [
              ./hosts/inspiron
              "${inputs.self}/users/seb/@inspiron"
            ];
          };
        };
      };

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

          formatter =
            (inputs.treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.nix";
              programs.nixfmt.enable = true;
              programs.prettier.enable = true;
            }).config.build.wrapper;
        };
    };
}
