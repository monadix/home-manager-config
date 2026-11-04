// Offline checks against the installed bundle and its actual Pi host. All files
// and credentials are synthetic and private; no provider or inference traffic.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const [host, bundle, cat, python, mergeScript] = process.argv.slice(2);
const modules = join(bundle, 'lib/pi-extensions/node_modules');
const home = await mkdtemp(join(tmpdir(), 'pi-credential-check-'));
const agentDir = join(home, '.pi/agent');
const cpaDir = join(agentDir, 'pi-cliproxyapi-provider');
const key = join(home, "key ' spaces $(not-a-command)");
const quote = value => "'" + value.replaceAll("'", "'\\''") + "'";
const expression = `!${cat} ${quote(key)}`;
let session;
try {
  process.env.HOME = home;
  process.env.PI_CODING_AGENT_DIR = agentDir;
  process.env.XDG_CONFIG_HOME = join(home, '.config');
  process.env.XDG_CACHE_HOME = join(home, '.cache');
  // Do not let ambient provider credentials/configuration influence the fixture.
  for (const name of Object.keys(process.env)) {
    if (name.startsWith('CLIPROXYAPI_') || /(?:API_KEY|AUTH_TOKEN|OAUTH_TOKEN)$/.test(name)
        || name === 'EXA_BASE_URL') delete process.env[name];
  }
  process.chdir(home);
  await mkdir(cpaDir, { recursive: true });
  await writeFile(key, 'synthetic-one\n', { mode: 0o600 });
  const configPath = join(cpaDir, 'config.json');
  const setCpa = apiKey => writeFile(configPath, JSON.stringify({
    baseUrl: 'https://cpa.fixture.invalid/v1', modelsDevEnabled: false,
    ...(apiKey === undefined ? {} : { apiKey }),
  }));
  await setCpa(expression);
  const defaults = join(home, 'defaults.json');
  const credentials = join(home, 'credentials.json');
  await writeFile(defaults, '{"packages":[]}');
  await writeFile(credentials, JSON.stringify({ deepseekApiKey: expression, opencodeGoApiKey: expression, exaApiKey: expression }));
  execFileSync(python, [mergeScript, agentDir, defaults, credentials]);
  const searchPath = join(agentDir, 'web-search.json');
  const searchConfig = JSON.parse(await readFile(searchPath, 'utf8'));
  await writeFile(searchPath, JSON.stringify({ ...searchConfig, provider: 'exa' }));

  let requests = 0;
  let expectedKey = 'synthetic-one';
  globalThis.fetch = async (url, init) => {
    assert.equal(String(url), 'https://cpa.fixture.invalid/v1/models');
    assert.equal(new Headers(init?.headers).get('authorization'), `Bearer ${expectedKey}`);
    requests++;
    return new Response(JSON.stringify({ data: [{ id: 'fixture-model' }] }));
  };
  process.env.CLIPROXYAPI_API_KEY = 'synthetic-env-must-not-win';
  process.env.DEEPSEEK_API_KEY = 'synthetic-env-must-not-win';
  process.env.OPENCODE_API_KEY = 'synthetic-env-must-not-win';
  const pi = await import(pathToFileURL(join(host, 'dist/index.js')));
  const { AuthStorage } = await import(pathToFileURL(join(host, 'dist/core/auth-storage.js')));
  const { ModelRegistry } = await import(pathToFileURL(join(host, 'dist/core/model-registry.js')));
  const storage = AuthStorage.inMemory();
  const runtime = await pi.ModelRuntime.create({ credentials: storage,
    modelsPath: join(agentDir, 'models.json'), refreshOnCreate: false });
  const loader = new pi.DefaultResourceLoader({ cwd: home, agentDir,
    additionalExtensionPaths: [join(modules, 'pi-cliproxyapi-provider/extensions/index.ts')],
    noSkills: true, noThemes: true, noPromptTemplates: true, noContextFiles: true });
  await loader.reload();
  assert.deepEqual(loader.getExtensions().errors, []);
  ({ session } = await pi.createAgentSession({ cwd: home, agentDir, modelRuntime: runtime,
    resourceLoader: loader, sessionManager: pi.SessionManager.inMemory(), noTools: 'all' }));
  const registry = new ModelRegistry(runtime);
  const refreshed = await runtime.refresh({ providers: ['cpa'], allowNetwork: true, force: true });
  assert.equal(refreshed.errors.size, 0);
  assert.equal(requests, 1);
  const cpaModel = registry.find('cpa', 'fixture-model');
  const deepseek = runtime.getModels('deepseek')[0];
  assert.ok(cpaModel);
  assert.ok(deepseek);
  const opencodeGo = runtime.getModels('opencode-go')[0];
  assert.ok(opencodeGo);
  for (const model of [cpaModel, deepseek, opencodeGo]) {
    // Same public auth API used by quota consumers; no quota request is sent.
    const auth = await registry.getApiKeyAndHeaders(model);
    assert.equal(auth.ok, true);
    assert.equal(auth.apiKey, 'synthetic-one');
  }
  await writeFile(key, 'synthetic-two\n');
  for (const provider of ['cpa', 'deepseek', 'opencode-go']) {
    assert.equal(await registry.getApiKeyForProvider(provider), 'synthetic-two');
    await storage.modify(provider, async () => ({ type: 'api_key', key: 'synthetic-saved' }));
    assert.equal(await registry.getApiKeyForProvider(provider), 'synthetic-saved');
    await storage.delete(provider);
    await storage.modify(provider, async () => ({ type: 'oauth', access: 'synthetic-oauth',
      refresh: 'synthetic-refresh', expires: 4102444800000 }));
    assert.equal(await registry.getApiKeyForProvider(provider), undefined);
    await storage.delete(provider);
  }
  expectedKey = 'synthetic-two';
  const runner = session.extensionRunner;
  const notifications = [];
  const context = runner.createCommandContext();
  context.ui.notify = message => notifications.push(message);
  await runner.getCommand('cliproxyapi').handler('refresh models', context);
  assert.equal(requests, 2);
  assert.ok(!notifications.some(message => /error|failed/i.test(message)));
  await writeFile(key, '');
  for (const provider of ['cpa', 'deepseek', 'opencode-go']) await assert.rejects(() => registry.getProviderAuth(provider));
  const failed = await runtime.refresh({ providers: ['cpa'], allowNetwork: true, force: true });
  assert.ok(failed.errors.has('cpa'));
  assert.equal(requests, 2);
  await runner.getCommand('cliproxyapi').handler('refresh models', context);
  assert.ok(notifications.some(message => /error|failed/i.test(message)));
  assert.equal(requests, 2);
  await rm(key);
  for (const provider of ['cpa', 'deepseek', 'opencode-go']) await assert.rejects(() => registry.getProviderAuth(provider));
  await setCpa(undefined);
  process.env.CLIPROXYAPI_API_KEY = 'synthetic-legacy-env';
  await session.reload();
  assert.equal(await registry.getApiKeyForProvider('cpa'), 'synthetic-legacy-env');
  delete process.env.CLIPROXYAPI_API_KEY;
  await storage.modify('cpa', async () => ({ type: 'api_key', key: 'synthetic-login' }));
  assert.equal(await registry.getApiKeyForProvider('cpa'), 'synthetic-login');
  console.log('CPA/DeepSeek/OpenCode Go: installed extension, both discovery paths, registry, rotation, saved/OAuth precedence, optional CPA and failures OK');

  // Exercise the native Exa command resolver shipped in this bundle.
  const { createJiti } = await import(pathToFileURL(join(host, 'node_modules/jiti/lib/jiti.mjs')));
  const jiti = createJiti(import.meta.url, { fsCache: false, moduleCache: false });
  const { resolveCredential } = await jiti.import(join(modules, 'pi-web-access/credential-source.ts'));
  const exaOptions = { provider: 'Exa', configuredValue: searchConfig.exaApiKey,
    environmentValue: 'synthetic-env-must-not-win' };
  await writeFile(key, 'synthetic-exa\n', { mode: 0o600 });
  assert.equal(await resolveCredential(exaOptions), 'synthetic-exa');
  await writeFile(key, 'synthetic-exa-rotated\n');
  assert.equal(await resolveCredential(exaOptions), 'synthetic-exa-rotated');
  await writeFile(key, '');
  await assert.rejects(() => resolveCredential(exaOptions), /command-empty/);
  await rm(key);
  await assert.rejects(() => resolveCredential(exaOptions), /command-failed/);
  await writeFile(key, 'synthetic-exa\n', { mode: 0o600 });

  // The packaged CLI is also the MCP entry point. Its compiled search path must
  // resolve the same file credential, not send the expression or use anonymous MCP.
  const { Client } = await import(pathToFileURL(join(modules, '@modelcontextprotocol/sdk/dist/esm/client/index.js')));
  const { StdioClientTransport } = await import(pathToFileURL(join(modules, '@modelcontextprotocol/sdk/dist/esm/client/stdio.js')));
  const mock = `import assert from 'node:assert/strict';
    globalThis.fetch = async (url, init) => {
      assert.equal(String(url), 'https://api.exa.ai/search');
      assert.equal(new Headers(init.headers).get('x-api-key'), 'synthetic-exa');
      return new Response(JSON.stringify({results:[{title:'offline-fixture-ok',url:'https://fixture.invalid',highlights:['fixture']}]}));
    };`;
  const transport = new StdioClientTransport({ command: process.execPath,
    args: ['--import', 'data:text/javascript,' + encodeURIComponent(mock), join(modules, 'pi-web-access/dist/mcp-cli.js')],
    env: { HOME: home, PI_CODING_AGENT_DIR: agentDir, PATH: process.env.PATH }, stderr: 'pipe' });
  const client = new Client({ name: 'offline-fixture', version: '1' });
  try {
    await client.connect(transport);
    const result = await client.callTool({ name: 'web_search', arguments: {
      query: 'offline fixture', provider: 'exa', includeContent: false,
    } });
    assert.notEqual(result.isError, true);
    assert.match(JSON.stringify(result.content), /offline-fixture-ok/);
  } finally {
    await client.close();
  }
  console.log('Exa: command resolution, rotation, failure, and compiled CLI/MCP offline search OK');
} finally {
  session?.dispose();
  await rm(home, { recursive: true, force: true });
}
