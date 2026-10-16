{ pkgs }:
pkgs.buildNpmPackage {
  pname = "pi-extensions";
  version = "1.0.0";
  src = ./.;
  npmDeps = pkgs.importNpmLock { npmRoot = ./.; };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  npmFlags = [ "--legacy-peer-deps" ];
  dontNpmBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pi-extensions
    cp -r node_modules $out/lib/pi-extensions/
    classifier="$out/lib/pi-extensions/node_modules/pi-permission-classifier"
    patch --directory="$classifier" -p1 < ${./classifier-routing.patch}
    cp ${./classifier-routing.mjs} "$classifier/src/classifier-routing.mjs"
    CLASSIFIER_ROUTING_MODULE="$classifier/src/classifier-routing.mjs" \
      CLASSIFIER_SOURCE_ROOT="$classifier/src" \
      CLASSIFIER_HOST_MODULE="${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo/dist/index.js" \
      ${pkgs.nodejs}/bin/node --test ${./test-classifier-routing.mjs}
    runHook postInstall
  '';
}
