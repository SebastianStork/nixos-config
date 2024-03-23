{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        home-manager = {
            url = "github:nix-community/home-manager/";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nix-index-database = {
            url = "github:Mic92/nix-index-database";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {nixpkgs, ...} @ inputs: let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
        nixosConfigurations = {
            dell-laptop = nixpkgs.lib.nixosSystem {
                specialArgs = {inherit inputs;};
                modules = [
                    ./hosts/dell-laptop
                    ./users/seb
                ];
            };
            seb-desktop = nixpkgs.lib.nixosSystem {
                specialArgs = {inherit inputs;};
                modules = [
                    ./hosts/seb-desktop
                    ./users/seb
                ];
            };
        };

        formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra.overrideAttrs {
            passthru.tests.version = {};
            postPatch = ''
                substituteInPlace src/alejandra/src/builder.rs \
                --replace '2 * build_ctx.indentation' '4 * build_ctx.indentation'
                substituteInPlace src/alejandra/src/rules/string.rs \
                --replace 'format!("  {}", line)' 'format!("    {}", line)'
                rm -r src/alejandra/tests
            '';
        };

        devShells.${system}.default = pkgs.mkShell {
            packages = [pkgs.sops];
        };
    };
}
