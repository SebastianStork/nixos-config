{
    assembleWrapper,
    pkgs,
    ...
}:
assembleWrapper {
    basePackage = pkgs.spotify;
    flags = ["--disable-gpu"];
}
