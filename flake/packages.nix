_:
{
  perSystem =
    { pkgs, ... }:
    {
       packages.kuma-cli = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "kuma-cli";
        version = "1.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "BigBoot";
          repo = "AutoKuma";
          rev = "v${finalAttrs.version}";
          hash = "sha256-o1W0ssR4cjzx9VWg3qS2RhJEe4y4Ez/Y+4yRgXs6q0Y=";
        };

        cargoRoot = "kuma-cli";
        buildAndTestSubdir = finalAttrs.cargoRoot;
        cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

        postUnpack = ''
          cp ${finalAttrs.src}/Cargo.lock ${finalAttrs.cargoRoot}/Cargo.lock
        '';

        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl.dev ];
      });
    };
}
