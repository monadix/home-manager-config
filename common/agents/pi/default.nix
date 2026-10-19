{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi-coding-agent;
  json = pkgs.formats.json { };
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  extensions = import ./extensions/_bundle.nix { inherit pkgs; };
  extensionNames = builtins.attrNames (builtins.fromJSON (builtins.readFile ./extensions/package.json)).dependencies;
  settings = json.generate "pi-settings-defaults.json" {
    theme = "dark";
    defaultProvider = "cpa";
    defaultModel = "gpt-6.1-sol";
    defaultThinkingLevel = "medium";
    npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
    packages = map (name: "${extensions}/lib/pi-extensions/node_modules/${name}") extensionNames;
  };
  package = pkgs.symlinkJoin {
    name = "pi-with-secrets-${pkgs.pi-coding-agent.version}";
    paths = [ pkgs.pi-coding-agent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi --run ${lib.escapeShellArg (''
        EXA_API_KEY="$( ${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.exa-api-key.path} )" || exit 1
        test -n "$EXA_API_KEY" || exit 1
        export EXA_API_KEY
      '' + lib.optionalString (cfg.cpaApiKeySecret != null) ''
        CLIPROXYAPI_API_KEY="$( ${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.${cfg.cpaApiKeySecret}.path} )" || exit 1
        test -n "$CLIPROXYAPI_API_KEY" || exit 1
        export CLIPROXYAPI_API_KEY
      '')}
    '';
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
      inherit package;
      extraPackages = [ pkgs.nodejs ];
      context = ../AGENTS.md;
      # settings.json stays writable for /settings, /model and pi install.
    };

    sops.secrets = {
      context7-api-key = { };
      exa-api-key = { };
    } // lib.optionalAttrs (cfg.cpaApiKeySecret != null) {
      ${cfg.cpaApiKeySecret} = { };
    };

    home.file = {
      ".pi/agent/mcp.json".text = builtins.toJSON {
        mcpServers.context7 = {
          url = "https://mcp.context7.com/mcp";
          description = "Look up current library and framework documentation.";
          exposure = "direct";
          headers.CONTEXT7_API_KEY =
            "!${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.context7-api-key.path}";
        };
      };
      ".pi/agent/pi-cliproxyapi-provider/config.json".text = builtins.toJSON {
        providerName = "cpa";
        baseUrl = "http://172.16.20.91:8317/v1";
        authRequired = true;
        authHeader = true;
      };
    };

    # Reapply declared defaults, preserving other runtime settings and packages.
    # Remove retired permission/reviewer packages and merge CPA context overrides.
    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.python3}/bin/python3 ${./merge-settings.py} \
        ${lib.escapeShellArg agentDir} ${settings}
    '';
  };
}
