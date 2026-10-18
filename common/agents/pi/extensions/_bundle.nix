{ pkgs }:
let
  piRoot = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo";
  scopeSandbox = pkgs.fetchFromGitHub {
    owner = "monadix";
    repo = "pi-scope-sandbox";
    rev = "60d50c7ddf2cc6e8bd2816fa0fd78f3680b3df70";
    hash = "sha256-8eTSBARc8L22Iw68zjiJWDCOCrixJEBegEo5OK61XVo=";
  };
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
    cp -r ${scopeSandbox} $out/lib/pi-extensions/node_modules/pi-scope-sandbox
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
    import { existsSync, realpathSync } from 'node:fs';
    import { pathToFileURL } from 'node:url';

    const modules = process.env.out + '/lib/pi-extensions/node_modules/';
    const parent = pathToFileURL(modules + 'pi-scope-sandbox/index.ts').href;
    assert.ok(!existsSync(modules + '@fadouse/pi-permission'), 'old permission stack must not be bundled');
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
    # Loading the real stack also checks TypeScript peers and required-child APIs.
    # No commands, model requests, production configuration or credentials are used.
    PI_OFFLINE=1 PI_TELEMETRY=0 node --input-type=module <<'JS'
    import assert from 'node:assert/strict';
    import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
    import { tmpdir } from 'node:os';
    import { join } from 'node:path';
    import { createRequire } from 'node:module';
    import { pathToFileURL } from 'node:url';
    const modules = process.env.out + '/lib/pi-extensions/node_modules/';
    const require = createRequire(modules + 'pi-subagents/package.json');
    const { createJiti } = require('jiti');
    const jiti = createJiti(modules + 'pi-scope-sandbox/index.ts');
    const sdk = await import(pathToFileURL('${piRoot}/dist/index.js'));
    const root = mkdtempSync(join(tmpdir(), 'pi-hm-stack-'));
    const agentDir = join(root, 'agent');
    const cwd = join(root, 'workspace');
    process.env.PI_CODING_AGENT_DIR = agentDir;
    process.env.PI_PERMISSION_SYSTEM_POLICY_AGENT_DIR = agentDir;
    for (const path of [cwd, join(agentDir, 'extensions/pi-permission-system'), join(agentDir, 'extensions/pi-permission-auto-review'), join(agentDir, 'extensions/pi-scope-sandbox')]) mkdirSync(path, { recursive: true });
    const reviewer = modules + '@mzwing/pi-permission-auto-review/dist/index.js';
    writeFileSync(join(agentDir, 'extensions/pi-permission-system/config.json'), JSON.stringify({ authorizerChain: ['auto-review'] }));
    writeFileSync(join(agentDir, 'extensions/pi-permission-auto-review/config.json'), JSON.stringify({ provider: 'cpa', model: 'codex-auto-review' }));
    writeFileSync(join(agentDir, 'extensions/pi-scope-sandbox/config.json'), JSON.stringify({ bwrap: '${pkgs.bubblewrap}/bin/bwrap', shell: '${pkgs.bash}/bin/bash', childExtensions: [reviewer] }));
    let session;
    try {
      const settingsManager = sdk.SettingsManager.inMemory({ packages: [], compaction: { enabled: false }, retry: { enabled: false } });
      const loader = new sdk.DefaultResourceLoader({ cwd, agentDir, settingsManager, noExtensions: true, noSkills: true, noPromptTemplates: true, noThemes: true, noContextFiles: true, additionalExtensionPaths: [modules + '@gotgenes/pi-permission-system/src/index.ts', reviewer, modules + 'pi-scope-sandbox/index.ts'] });
      await loader.reload();
      assert.deepEqual(loader.getExtensions().errors, []);
      const modelRuntime = await sdk.ModelRuntime.create({ authPath: join(agentDir, 'auth.json'), modelsPath: null, modelsStorePath: join(agentDir, 'models-cache.json'), refreshOnCreate: false, allowModelNetwork: false });
      ({ session } = await sdk.createAgentSession({ cwd, agentDir, modelRuntime, settingsManager, resourceLoader: loader, sessionManager: sdk.SessionManager.inMemory(cwd) }));
      const errors = [];
      await session.bindExtensions({ mode: 'json', onError: error => errors.push(error) });
      assert.deepEqual(errors, []);
      const { getPermissionsService } = await jiti.import(modules + '@gotgenes/pi-permission-system/src/service.ts');
      const sessionId = session.sessionManager.getSessionId();
      assert.ok(getPermissionsService(sessionId));
      assert.ok(session.getCallableToolNames().includes('scope_sandbox_authorize'));
      const { registerRequiredChildExtensions } = await jiti.import('pi-subagents/required-child-extensions');
      let probe;
      try { assert.throws(() => { probe = registerRequiredChildExtensions({ sessionId, extensions: [] }); }, /already registered/); }
      finally { probe?.dispose(); }
      console.log('Pi permission/reviewer/sandbox stack loads offline with required child registration');
    } finally {
      if (session) { await session.extensionRunner.emit({ type: 'session_shutdown' }); session.dispose(); }
      rmSync(root, { recursive: true, force: true });
    }
    JS
    runHook postInstallCheck
  '';
}
