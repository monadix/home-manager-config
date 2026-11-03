{ pkgs }:
let
  piRoot = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo";
in
pkgs.buildNpmPackage {
  pname = "pi-extensions";
  version = "1.0.0";
  src = ./.;
  npmDeps = pkgs.importNpmLock { npmRoot = ./.; };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  # Pack Git sources rewritten to local paths by importNpmLock, not symlinks
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

  doInstallCheck = true;
  nativeInstallCheckInputs = [ pkgs.nodejs pkgs.python3 ];
  installCheckPhase = ''
    runHook preInstallCheck
    PI_OFFLINE=1 PI_TELEMETRY=0 node --experimental-import-meta-resolve --input-type=module <<'JS'
    import assert from 'node:assert/strict';
    import { realpathSync } from 'node:fs';
    import { pathToFileURL } from 'node:url';

    const modules = process.env.out + '/lib/pi-extensions/node_modules/';
    const host = '${piRoot}';
    const peers = [
      ['@earendil-works/pi-ai', host + '/node_modules/@earendil-works/pi-ai', 'Type', 'object'],
      ['@earendil-works/pi-ai/compat', host + '/node_modules/@earendil-works/pi-ai', 'completeSimple', 'function'],
      ['@earendil-works/pi-agent-core', host + '/node_modules/@earendil-works/pi-agent-core', 'Agent', 'function'],
      ['@earendil-works/pi-coding-agent', host, 'createAgentSession', 'function'],
      ['@earendil-works/pi-tui', host + '/node_modules/@earendil-works/pi-tui', 'Container', 'function'],
      ['typebox', host + '/node_modules/typebox', 'Type', 'object'],
    ];
    for (const [name, target, symbol, type] of peers) {
      const packageName = name.replace('/compat', "");
      assert.equal(realpathSync(modules + packageName), realpathSync(target));
      for (const consumer of ['pi-subagents', 'pi-cliproxyapi-provider']) {
        const parent = pathToFileURL(modules + consumer + '/package.json').href;
        const resolved = import.meta.resolve(name, parent);
        assert.ok(resolved.startsWith(pathToFileURL(realpathSync(target) + '/').href), name);
        assert.equal(typeof (await import(resolved))[symbol], type, name + '.' + symbol);
        console.log('Host peer import OK:', consumer, name);
      }
    }
    JS
    PI_OFFLINE=1 PI_TELEMETRY=0 node ${./test-credentials.mjs} \
      ${piRoot} $out ${pkgs.coreutils}/bin/cat ${pkgs.python3}/bin/python3 ${../merge-settings.py}
    runHook postInstallCheck
  '';
}
