{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper {
    basePackage = pkgs.obsidian;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
