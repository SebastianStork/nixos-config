{ buildGoModule, nebula, ... }:
buildGoModule {
  pname = "nebula-check-certs";
  inherit (nebula) version src;
  postPatch = ''
    install -D -m 0644 ${./main.go} cmd/nebula-check-certs/main.go
  '';
  vendorHash = nebula.drvAttrs.vendorHash;
  subPackages = [ "cmd/nebula-check-certs" ];
  doCheck = false;
  meta.mainProgram = "nebula-check-certs";
}
