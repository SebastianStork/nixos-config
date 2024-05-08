{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper {
    basePackage = pkgs.spotify;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
