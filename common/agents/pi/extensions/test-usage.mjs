// Check the packed usage source and registration against the bundle's Pi host.
// No user configuration, credentials, session, or provider requests are used.
import assert from 'node:assert/strict';
import { lstatSync, readFileSync, readdirSync } from 'node:fs';
import { mkdtemp, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const [host, bundle, source] = process.argv.slice(2);
const installed = join(bundle, 'lib/pi-extensions/node_modules/pi-universal-usage');
assert.equal(lstatSync(installed).isSymbolicLink(), false);
const pkg = JSON.parse(readFileSync(join(source, 'package.json'), 'utf8'));
assert.equal(pkg.name, 'pi-universal-usage');
assert.equal(pkg.version, '0.1.0');
assert.deepEqual(pkg.pi.extensions, ['./extensions/index.ts']);
const expected = ['package.json'];
for (const resource of pkg.files) {
  const path = join(source, resource);
  if (lstatSync(path).isDirectory()) {
    expected.push(...readdirSync(path, { recursive: true, withFileTypes: true })
      .filter(entry => entry.isFile())
      .map(entry => join(entry.parentPath, entry.name).slice(source.length + 1)));
  } else {
    assert.ok(lstatSync(path).isFile(), resource);
    expected.push(resource);
  }
}
const actual = readdirSync(installed, { recursive: true, withFileTypes: true })
  .filter(entry => !entry.isDirectory())
  .map(entry => join(entry.parentPath, entry.name).slice(installed.length + 1));
assert.equal(expected.length, 32, 'Reviewed usage resource set changed');
assert.deepEqual(actual.sort(), expected.sort(), 'Usage package resource set');
for (const path of expected) {
  assert.equal(lstatSync(join(installed, path)).isSymbolicLink(), false, path);
  assert.deepEqual(readFileSync(join(installed, path)), readFileSync(join(source, path)), path);
}
console.log('Usage provenance: all 32 packaged resources byte-identical to pinned source');

const home = await mkdtemp(join(tmpdir(), 'pi-usage-check-'));
const previousCwd = process.cwd();
const previousFetch = globalThis.fetch;
try {
  process.env.HOME = home;
  process.env.PI_CODING_AGENT_DIR = join(home, '.pi/agent');
  process.env.XDG_CONFIG_HOME = join(home, '.config');
  process.env.XDG_CACHE_HOME = join(home, '.cache');
  for (const name of Object.keys(process.env)) {
    if (name.startsWith('CLIPROXYAPI_') || /(?:API_KEY|AUTH_TOKEN|OAUTH_TOKEN)$/.test(name)) {
      delete process.env[name];
    }
  }
  await mkdir(process.env.PI_CODING_AGENT_DIR, { recursive: true });
  process.chdir(home);
  let requests = 0;
  globalThis.fetch = async () => {
    requests++;
    throw new Error('Network forbidden during usage registration');
  };
  const pi = await import(pathToFileURL(join(host, 'dist/index.js')));
  const result = await pi.discoverAndLoadExtensions([installed], home, process.env.PI_CODING_AGENT_DIR);
  assert.deepEqual(result.errors, []);
  assert.equal(result.extensions.length, 1);
  const [extension] = result.extensions;
  assert.equal(extension.resolvedPath, join(installed, 'extensions/index.ts'));
  assert.deepEqual([...extension.commands.keys()], ['usage']);
  assert.equal(typeof extension.commands.get('usage').handler, 'function');
  for (const event of ['session_start', 'session_shutdown', 'model_select', 'turn_start', 'agent_end', 'after_provider_response']) {
    assert.ok(extension.handlers.has(event), event);
  }
  assert.equal(requests, 0, 'No hidden load-time fetch');
  console.log('Usage load: built package, isolated HOME/config/cwd, one /usage command, zero fetches');
} finally {
  globalThis.fetch = previousFetch;
  process.chdir(previousCwd);
  await rm(home, { recursive: true, force: true });
}
