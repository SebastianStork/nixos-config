{
  self,
  lib,
  writeShellScriptBin,
  nix,
  ...
}:
writeShellScriptBin "check-hash-stability" ''
  exec ${lib.getExe nix} eval \
    --impure \
    --expr '
      import ${./check.nix} {
        flake = builtins.getFlake "path:${self}";
      }
    ' \
    >/dev/null
''
