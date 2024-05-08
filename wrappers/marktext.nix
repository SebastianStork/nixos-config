{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper {
    basePackage = pkgs.marktext;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
