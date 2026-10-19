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
  npmFlags = [ "--legacy-peer-deps" "--ignore-scripts" ];
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
  nativeInstallCheckInputs = [ pkgs.nodejs ];
  installCheckPhase = ''
    runHook preInstallCheck
    PI_OFFLINE=1 PI_TELEMETRY=0 node --experimental-import-meta-resolve --input-type=module <<'JS'
    import assert from 'node:assert/strict';
    import { realpathSync } from 'node:fs';
    import { pathToFileURL } from 'node:url';

    const modules = process.env.out + '/lib/pi-extensions/node_modules/';
    const parent = pathToFileURL(modules + 'pi-subagents/package.json').href;
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
      const resolved = import.meta.resolve(name, parent);
      assert.ok(resolved.startsWith(pathToFileURL(realpathSync(target) + '/').href), name);
      assert.equal(typeof (await import(resolved))[symbol], type, name + '.' + symbol);
      console.log('Host peer import OK:', name);
    }
    JS
    runHook postInstallCheck
  '';
}
