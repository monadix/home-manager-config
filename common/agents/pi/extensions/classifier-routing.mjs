// Route the HM default without changing explicit flag overrides or other judges.
export function reviewerConfig(config, override, sessionProvider) {
  if (!config) return config;
  const pair = override ?? (
    config.provider === "cpa" && config.model === "codex-auto-review" && sessionProvider === "openai"
      ? { provider: "openai", model: "codex-auto-review" }
      : config
  );
  return pair === config ? config : { ...config, provider: pair.provider, model: pair.model };
}
