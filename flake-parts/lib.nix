{ self, lib, ... }:
{
  flake.lib = {
    concatWords = words: words |> lib.concatStringsSep " ";

    headOrNull = list: if list == [ ] then null else list |> lib.head;

    exactlyOne =
      description: values:
      if lib.length values == 1 then
        lib.head values
      else
        throw "Expected exactly one ${description}, found ${values |> lib.length |> lib.toString}";

    atMostOne =
      description: values:
      if lib.length values <= 1 then
        self.lib.headOrNull values
      else
        throw "Expected at most one ${description}, found ${values |> lib.length |> lib.toString}";

    uncheckedHostConfig =
      host:
      (host.extendModules {
        modules = [ { _module.check = false; } ];
      }).config;

    privateDomain = "splitleaf.de";

    adminAgePublicKey = "age1pq1ygtfgj0fnjsxcnrgffq0u7c36v9jav2qsrl45pctp9686s57csjt8w48yp35eqhlmy4cefd28gupwsj3rvsv0yp2jave6zs3jpa8egjke8xhpqcta0qc2umuxfzke97kcj4eh83c00qqyqkxwzvfe00944z9c24x727vsupyud5sm7knkk32xa0a337d5dvse6y4ft8u36um5wfwtz66yzqk604fgvzqvmpyr3x8ukhs2cnjharqr3c6y8e8zms7vfq53kvyzwekytckws6mvxa9pfjjxazjc0g3cexy2yew5z0m2g7tmqyrr6fme3egvek8gwk0hquclq9xrfcp54fggl0axfjsup2wrsf69qn9hl03g7ynn905vs3x0g25lsrmq0758chgdfk37vhc3swqqsdhvd85ckysk34nq6r9wct79e42upfq5tkus7dhc44vd4vu0wdqfg3ctpldpfrhv9myzhrh066p2xm202v7ynxmmrr8l0p5hapefaw55r2te9yeey056ezr0kqh3zv54ggxgdrryz7ac9gplz55axf3nkymyvyjnr9aryt8m0j6f96k5wpvgps5hy53pkm6f6d5qa7sh36f4tplkh9yj5fpvypfu523tq7rgqnklp68a23q5smvwt0tcl2tqr4wrxpkv7eza24mwa7xrmhgztu3mp4e8p5fnc2ss9pkknk3zq4hcu777zz5ekrcg4apnlltvwduu6wmlpapqr2465k2flgfrwzzlgz68s4kkedgmar9spz0kp3yqvds0e5ggfrjkty2hfnmcntzxs62mzt0rmtxdfk9cq3pyjm5ltxkctp6qvjscssn08gsdnkdkdu6gwug6y7g7y7gj9escqcrw9faua23vv9c9u53gh8mr9fnyqxke9vpfzsvmgguzn8ujc4fef9wax9furymysx9fru4vam3vv66a0z7y9u4xgg2jd980wqjvptc7vzsq6gx6mdehnu7gpp2vm8dnfda4m5kqa8fx3spyhezkp2qhj5lzzqkarr6vxcqj0salfv4qg5v53j8qvlt2z4z00rw2kksrwnxtneqp3g5qe9msd9zucmlqkpu772zqgjs9sxawx0r7zq9lf6lucf2tp2c2qcdw7rpw9674238tt5c58rm0mrsyy8gasghh5c6rgj8uz75pzzpny0f3ycee9tssyr9zzjuxlf7nxqhfq4mtcnyssjj0k93dkczhsgz6yh9tcez6mu3h7ngtjt4dgxzl2dxs6tvl8ajg849pkhacg4muspvvqfnmr3e3a0r2hk4tjqpex7dgfg6rxyhyx4gdtxjkk66n364f7twkhdzfvth2hdlgxtkr2a4kdcsw9njsq7englpvp4fu6u9gpuz8lvx8qg22m34q5s72u2q3y4z5h34659txdqnks5jvgpfygrkpu3vx44t3lx08s5ghjv9vrrnq5xpmlt2kcdm8xufwuzuzyawq5mtqnz6jp2evufdq57j5f2knt5fgp3nveq9smam4sl7han8gs3r9lthzammq7rm0ymv66vuz7cp07vryrm6j2d7dzx6hfwxp5f3gjhrtjvp902fqzrrl9y3axec78te9v8dcsklzzkf9pf7k8c9q3qhg390gyf469s3wvu2m05k0ax2cy5nw630nvcwqawvwvwfjlmu5zzckz9ky9hm8pqtnkasdefmrqxzq6wywfh9gs2flt45wwrfjmsctyaxpsnw4eauetexfp7qy0lygmxac5p76y3gtvd8q4wtjs32eswz5epykevrndfuv44nj8hgh0mmcj3mnygfz5d6cvzp443rz0p8ng7jrcygxurylpdzn5l3k6r00jzcjvmuqr2z5jjf29x7l4zjqwlmrz4djnz5vrvvfysttuh3ncmdzqcvk7q4uwfvhk6k69k692mamllpwvdvsl90";

    isPrivateDomain = domain: domain |> lib.hasSuffix ".${self.lib.privateDomain}";

    listNixFilesRecursively =
      dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

    listDirectoryNames =
      path:
      path
      |> lib.readDir
      |> lib.filterAttrs (_: type: type == "directory")
      |> lib.attrNames;

    genAttrs = f: names: lib.genAttrs names f;

    genAttrs' = f: names: lib.genAttrs' names f;

    mkInvalidConfigMessage = subject: reason: "Invalid configuration for ${subject}: ${reason}.";

    mkPackageAtLeast =
      { stable, pinned }:
      packageName: minimumVersion:
      let
        stablePackage = stable.${packageName} or null;
      in
      if stablePackage != null && lib.versionAtLeast stablePackage.version minimumVersion then
        lib.warn ''
          packageAtLeast: stable `${packageName}` ${stablePackage.version} now satisfies minimum version ${minimumVersion}; remove this override
        '' stablePackage
      else
        pinned packageName minimumVersion;

    mkUnprotectedMessage =
      name:
      self.lib.mkInvalidConfigMessage name "the service must use a private domain until access control is configured";

    relativePath = path: path |> lib.toString |> lib.removePrefix "${self}/";

    isolateStorePath =
      path:
      if path |> lib.hasPrefix "${self}/" then
        builtins.path {
          inherit path;
          name = path |> lib.removePrefix "${self}/" |> lib.strings.sanitizeDerivationName;
        }
      else
        path;

    nebulaHostInventory =
      host:
      let
        overlay = host.config.custom.networking.overlay;
        inherit (overlay) nebula;
      in
      {
        name = host.config.networking.hostName;
        certificate = lib.toString nebula.certificateFile;
        certificateOutput = self.lib.relativePath nebula.certificateFile;
        publicKey = lib.toString nebula.publicKeyFile;
        ca = lib.toString nebula.caCertificateFile;
        networks = [ overlay.cidr ];
        inherit (nebula) unsafeNetworks;
        groups = overlay.accessGroups;
      };

    types.existingPath = (lib.types.addCheck lib.types.path lib.pathExists) // {
      description = "path that exists";
    };
  };
}
