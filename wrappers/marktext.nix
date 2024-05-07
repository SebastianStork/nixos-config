{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper "marktext" {
    basePackage = pkgs.marktext;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
