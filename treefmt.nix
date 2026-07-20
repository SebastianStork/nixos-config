{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    just.enable = true;
    shfmt.enable = true;
  };
  settings.formatter.shfmt.options = [ "--space-redirects" ];
}
