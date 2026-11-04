{ pkgs }:
let
  piRoot = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo";
  cpaSource = pkgs.fetchFromGitHub {
    owner = "monadix";
    repo = "pi-cliproxyapi-provider";
    rev = "4dac57b4fd013c5b39b2f5db75a0998ec94bbc69";
    hash = "sha256-ANB/Ey8trcOOrPQNFHEZCujuE1+ahpKp4hJCDCZFals=";
  };
  cpaUrl = "https://github.com/${cpaSource.owner}/${cpaSource.repo}/archive/${cpaSource.rev}.tar.gz";
  usageSource = pkgs.fetchFromGitHub {
    owner = "monadix";
    repo = "pi-universal-usage";
    rev = "61df39c57fe429afdbf2fe21565d93ad230309ee";
    hash = "sha256-yvmP7quqELBW7DiUteHVrPdwSZrJxNIm7f6zZWNYxsM=";
  };
  usageUrl = "https://github.com/${usageSource.owner}/${usageSource.repo}/archive/${usageSource.rev}.tar.gz";
  package = pkgs.lib.importJSON ./package.json;
  packageLock = pkgs.lib.importJSON ./package-lock.json;
in
assert package.dependencies.pi-cliproxyapi-provider == cpaUrl;
assert packageLock.packages."".dependencies.pi-cliproxyapi-provider == cpaUrl;
assert packageLock.packages."node_modules/pi-cliproxyapi-provider".resolved == cpaUrl;
assert cpaSource.urls == [ cpaUrl ] && !(cpaSource ? netrcPhase);
assert (cpaSource.netrcImpureEnvVars or [ ]) == [ ];
assert package.dependencies.pi-universal-usage == usageUrl;
assert packageLock.packages."".dependencies.pi-universal-usage == usageUrl;
assert packageLock.packages."node_modules/pi-universal-usage".resolved == usageUrl;
assert usageSource.urls == [ usageUrl ] && !(usageSource ? netrcPhase);
assert (usageSource.netrcImpureEnvVars or [ ]) == [ ];
pkgs.buildNpmPackage {
  pname = "pi-extensions";
  version = "1.0.0";
  src = ./.;
  npmDeps = pkgs.importNpmLock {
    npmRoot = ./.;
    packageSourceOverrides = {
      "node_modules/pi-cliproxyapi-provider" = cpaSource;
      "node_modules/pi-universal-usage" = usageSource;
    };
    # npm repacks this directory; the archive's integrity is not its npm tar hash.
    # fetchFromGitHub already verifies the unpacked source's recursive hash.
    packageLock = packageLock // {
      packages = packageLock.packages // {
        "node_modules/pi-cliproxyapi-provider" = builtins.removeAttrs
          packageLock.packages."node_modules/pi-cliproxyapi-provider" [ "integrity" ];
        "node_modules/pi-universal-usage" = builtins.removeAttrs
          packageLock.packages."node_modules/pi-universal-usage" [ "integrity" ];
      };
    };
  };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  passthru = { inherit cpaSource usageSource; };
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

  doInstallCheck = true;
  nativeInstallCheckInputs = [ pkgs.nodejs pkgs.python3 ];
  installCheckPhase = ''
    runHook preInstallCheck
    python3 ${./test-provenance.py} ${cpaSource} \
      $out/lib/pi-extensions/node_modules/pi-cliproxyapi-provider
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
      for (const consumer of ['pi-subagents', 'pi-cliproxyapi-provider', 'pi-universal-usage']) {
        const parent = pathToFileURL(modules + consumer + '/package.json').href;
        const resolved = import.meta.resolve(name, parent);
        assert.ok(resolved.startsWith(pathToFileURL(realpathSync(target) + '/').href), name);
        assert.equal(typeof (await import(resolved))[symbol], type, name + '.' + symbol);
        console.log('Host peer import OK:', consumer, name);
      }
    }
    JS
    PI_OFFLINE=1 PI_TELEMETRY=0 node ${./test-usage.mjs} \
      ${piRoot} $out ${usageSource}
    PI_OFFLINE=1 PI_TELEMETRY=0 node ${./test-credentials.mjs} \
      ${piRoot} $out ${pkgs.coreutils}/bin/cat ${pkgs.python3}/bin/python3 ${../merge-settings.py}
    runHook postInstallCheck
  '';
}
