{ buildGoModule, nebula, ... }:
buildGoModule {
  pname = "nebula-recert";
  inherit (nebula) version src;
  postPatch = ''
    install -D -m 0644 ${./main.go} cmd/nebula-recert/main.go
  '';
  vendorHash = nebula.drvAttrs.vendorHash;
  subPackages = [ "cmd/nebula-recert" ];
  doCheck = false;
  meta.mainProgram = "nebula-recert";
}
