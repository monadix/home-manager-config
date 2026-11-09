{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi-coding-agent;
  json = pkgs.formats.json { };
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  extensions = import ./extensions/_bundle.nix { inherit pkgs; };
  extensionNames = builtins.attrNames (import ./extensions/_pins.nix).deps;
  settings = json.generate "pi-settings-defaults.json" {
    theme = "dark";
    defaultProvider = "cpa";
    defaultModel = "gpt-6.1-sol";
    defaultThinkingLevel = "medium";
    defaultTools = [ "+codemode" ];
    retry = {
      enabled = true;
      maxRetries = 20;
      baseDelayMs = 5000;
      maxAgentDelayMs = 60000;
    };
    npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
    packages = map (name: "${extensions}/lib/pi-extensions/node_modules/${name}") extensionNames;
  };
  secretCommand = cat: name:
    "!${cat} ${lib.escapeShellArg config.sops.secrets.${name}.path}";
  # CPA accepts only allowlisted command names, not paths.
  cpaSecretCommand = secretCommand "cat";
  credentials = json.generate "pi-credential-defaults.json" {
    deepseekApiKey = secretCommand "${pkgs.coreutils}/bin/cat" "deepseek-api-key";
    opencodeGoApiKey = secretCommand "${pkgs.coreutils}/bin/cat" "opencode-api-key";
    exaApiKey = secretCommand "${pkgs.coreutils}/bin/cat" "exa-api-key";
  };
in
{
  options.programs.pi-coding-agent.cpaApiKeySecret = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "pi-cpa-api-key";
    description = "Optional key in the SOPS secrets file containing the CPA API key.";
  };

  config = {
    programs.pi-coding-agent = {
      enable = true;
      cpaApiKeySecret = "pi-cpa-api-key";
      extraPackages = [ pkgs.nodejs ];
      context = ../AGENTS.md;
      # settings.json stays writable for /settings, /model and pi install.
    };

    sops.secrets = {
      context7-api-key = { };
      deepseek-api-key = { };
      opencode-api-key = { };
      exa-api-key = { };
      internal-cpa-url = { };
    } // lib.optionalAttrs (cfg.cpaApiKeySecret != null) {
      ${cfg.cpaApiKeySecret} = { };
    };

    home.file = (import ./_subagents.nix) // {
      ".pi/agent/mcp.json".text = builtins.toJSON {
        mcpServers.context7 = {
          url = "https://mcp.context7.com/mcp";
          description = "Look up current library and framework documentation.";
          exposure = "direct";
          headers.CONTEXT7_API_KEY =
            "!${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.context7-api-key.path}";
        };
      };
      ".pi/agent/pi-cliproxyapi-provider/config.json".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates."pi-cliproxyapi-provider.json".path;
    };

    sops.templates."pi-cliproxyapi-provider.json".content = builtins.toJSON ({
      providerName = "cpa";
      baseUrl = config.sops.placeholder.internal-cpa-url;
      authRequired = true;
      authHeader = true;
    } // lib.optionalAttrs (cfg.cpaApiKeySecret != null) {
      apiKey = cpaSecretCommand cfg.cpaApiKeySecret;
    });

    # Reapply declared defaults, preserving other runtime settings and packages.
    # Remove retired permission/reviewer packages and merge CPA context overrides.
    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.python3}/bin/python3 ${./merge-settings.py} \
        ${lib.escapeShellArg agentDir} ${settings} ${credentials}
    '';
  };
}
