{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
assembleWrapper "obsidian" {
    basePackage = pkgs.obsidian;
    flags = [(lib.mkIf disableGPU "--disable-gpu")];
}
