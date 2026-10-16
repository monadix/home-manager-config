import assert from "node:assert/strict";
import test from "node:test";
import path from "node:path";

const { reviewerConfig } = await import(process.env.CLASSIFIER_ROUTING_MODULE ?? "./classifier-routing.mjs");
const defaults = { provider: "cpa", model: "codex-auto-review", timeoutMs: 30000 };

test("direct OpenAI uses its own reviewer and other providers use CPA", () => {
  for (const provider of ["openai", "cpa", "anthropic", "openai-codex", undefined, "openai"]) {
    const result = reviewerConfig(defaults, undefined, provider);
    assert.equal(result.provider, provider === "openai" ? "openai" : "cpa");
    assert.equal(result.model, "codex-auto-review");
    assert.equal(result.timeoutMs, 30000);
  }
  assert.equal(defaults.provider, "cpa");
});

test("explicit flags and unrelated judge selections retain precedence", () => {
  const override = { provider: "cpa", model: "explicit" };
  assert.deepEqual(reviewerConfig(defaults, override, "openai"), { ...defaults, ...override });
  const custom = { provider: "local", model: "judge" };
  assert.deepEqual(reviewerConfig(custom, undefined, "openai"), custom);
  assert.deepEqual(reviewerConfig({}, undefined, "openai"), {});
  assert.equal(reviewerConfig(undefined, override, "openai"), undefined);
});

test("built classifier uses routed auth and status, and still fails safe", {
  skip: !process.env.CLASSIFIER_SOURCE_ROOT,
}, async () => {
  const root = process.env.CLASSIFIER_SOURCE_ROOT;
  const { createJiti } = await import(path.resolve(root, "../../jiti/lib/jiti.mjs"));
  const jiti = createJiti(import.meta.url, { alias: {
    "@earendil-works/pi-coding-agent": process.env.CLASSIFIER_HOST_MODULE,
  } });
  const { createPermissionModelCommand } = await jiti.import(root + "/command.ts");
  const { createClassifierReviewer } = await jiti.import(root + "/reviewer.ts");
  const { resolveJudge, formatJudgeStatus } = await jiti.import(root + "/judge.ts");
  let active = "openai", available = true, authOk = true;
  const called = [];
  const registry = {
    find: (provider, id) => available ? { provider, id, api: "openai-responses" } : undefined,
    getApiKeyAndHeaders: async (model) => ({ ok: authOk, apiKey: "synthetic-" + model.provider }),
  };
  const config = { ...defaults, contextBudgetBytes: 8192 };
  const authorize = createClassifierReviewer({
    getConfig: () => reviewerConfig(config, undefined, active),
    getSessionModel: () => ({ provider: active }),
    getRegistry: () => registry,
    complete: async (model, _context, options) => {
      assert.equal(options.apiKey, "synthetic-" + model.provider);
      assert.equal(options.toolChoice, "required");
      called.push(model.provider);
      return { stopReason: "toolUse", content: [{ type: "toolCall", arguments: { verdict: "allow" } }] };
    },
  });
  const details = { requestId: "test", surface: "bash", payload: { request: {
    surface: "bash", value: "git status --short", executedUnit: null, commandContext: null,
    requester: { forwarded: false, agentName: null, sessionId: null },
  } } };
  const log = { review() {}, debug() {} };
  const notifications = [];
  const command = createPermissionModelCommand({
    getConfig: () => reviewerConfig(config, undefined, active),
    getOverride: () => undefined,
  });
  for (active of ["openai", "cpa", "anthropic", "openai"]) {
    assert.deepEqual(await authorize(details, undefined, log), { kind: "allow" });
    const expected = active === "openai" ? "openai" : "cpa";
    assert.equal(called.at(-1), expected);
    const judge = resolveJudge(undefined, reviewerConfig(config, undefined, active), registry, { provider: active });
    assert.equal(formatJudgeStatus(judge), `judge:${expected}/codex-auto-review`);
    await command.handler("", {
      mode: "print", model: { provider: active }, modelRegistry: registry,
      ui: { notify: (text) => notifications.push(text) },
    });
    assert.ok(notifications.at(-1).includes(`judge:${expected}/codex-auto-review`));
  }
  available = false;
  assert.deepEqual(await authorize(details, undefined, log), { kind: "defer" });
  available = true;
  authOk = false;
  assert.deepEqual(await authorize(details, undefined, log), { kind: "defer" });
  authOk = true;
  assert.deepEqual(await authorize({ ...details, surface: "external_directory" }, undefined, log), { kind: "defer" });
  assert.equal(called.length, 4);
});
