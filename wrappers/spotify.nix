{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper "spotify" {
    basePackage = pkgs.spotify;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
