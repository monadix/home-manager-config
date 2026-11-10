{ pkgs, pi ? pkgs.pi-coding-agent }:
let
  inherit (pkgs) lib;
  piRoot = "${pi}/lib/node_modules/pi-monorepo";
  pins = import ./_pins.nix;
  gitDeps = lib.filterAttrs (_: dep: builtins.isAttrs dep) pins.deps;
  sources = builtins.mapAttrs
    (_: dep: pkgs.fetchFromGitHub { inherit (dep) owner repo rev hash; })
    gitDeps;
  urls = builtins.mapAttrs
    (_: source: "https://github.com/${source.owner}/${source.repo}/archive/${source.rev}.tar.gz")
    sources;
  dependencies = builtins.mapAttrs
    (name: dep: if builtins.isAttrs dep then urls.${name} else dep)
    pins.deps;
  manifest = {
    inherit (pins) name version;
    private = true;
    inherit dependencies;
  };
  packageSourceOverrides = lib.mapAttrs'
    (name: source: lib.nameValuePair "node_modules/${name}" source)
    sources;
  packageLock = lib.importJSON ./package-lock.json;
  npmRoot = pkgs.runCommand "pi-extensions-npm-root" { } ''
    mkdir -p $out
    cp ${pkgs.writeText "package.json" (builtins.toJSON manifest)} $out/package.json
  '';
  # npm repacks overridden sources, so their archive integrity no longer
  # matches. fetchFromGitHub already hashes the unpacked tree.
  lockPackages = builtins.mapAttrs
    (path: entry:
      if packageSourceOverrides ? ${path}
      then builtins.removeAttrs entry [ "integrity" ]
      else entry)
    packageLock.packages;
in
assert packageLock.packages."".name == pins.name;
assert lib.all
  (name: packageLock.packages."node_modules/${name}".resolved == urls.${name})
  (builtins.attrNames urls);
assert lib.all (name: !(sources.${name} ? netrcPhase)) (builtins.attrNames sources);
assert lib.all (name: (sources.${name}.netrcImpureEnvVars or [ ]) == [ ])
  (builtins.attrNames sources);
pkgs.buildNpmPackage {
  pname = "pi-extensions";
  version = pins.version;
  src = npmRoot;
  npmDeps = pkgs.importNpmLock {
    package = manifest;
    inherit packageSourceOverrides;
    packageLock = packageLock // { packages = lockPackages; };
  };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  passthru = { inherit npmRoot; };
  # Pack sources rewritten to local paths by importNpmLock, not symlinks
  # outside this node_modules tree (where host peers would not resolve).
  npmFlags = [ "--legacy-peer-deps" "--ignore-scripts" "--install-links" ];
  npmRebuildFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pi-extensions
    cp -r node_modules $out/lib/pi-extensions/
    # Native ESM imports need the same host peers that Pi supplies to extensions.
    mkdir -p $out/lib/pi-extensions/node_modules/@earendil-works
    for peer in pi-ai pi-agent-core pi-tui; do
      ln -s ${piRoot}/node_modules/@earendil-works/$peer \
        $out/lib/pi-extensions/node_modules/@earendil-works/$peer
    done
    ln -s ${piRoot} $out/lib/pi-extensions/node_modules/@earendil-works/pi-coding-agent
    ln -s ${piRoot}/node_modules/typebox $out/lib/pi-extensions/node_modules/typebox
    runHook postInstall
  '';
}
