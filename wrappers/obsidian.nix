{
    assembleWrapper,
    pkgs,
    ...
}:
assembleWrapper {
    basePackage = pkgs.obsidian;
    flags = ["--disable-gpu"];
}
