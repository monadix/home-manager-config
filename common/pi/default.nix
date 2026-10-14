{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi-coding-agent;
  json = pkgs.formats.json { };
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  settings = json.generate "pi-settings-defaults.json" {
    theme = "dark";
    defaultProvider = "cpa";
    defaultModel = "gpt-6.1-sol";
    defaultThinkingLevel = "medium";
    npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
    packages = [
      "npm:pi-vim@0.14.2"
      "npm:pi-permission-classifier@0.5.2"
      "npm:@gotgenes/pi-permission-system@40.2.0"
      "npm:pi-web-access@0.30.0"
      "npm:pi-subagents@0.70.0"
      "npm:pi-cliproxyapi-provider@0.15.43"
    ];
  };
  package = pkgs.symlinkJoin {
    name = "pi-with-cpa-secret-${pkgs.pi-coding-agent.version}";
    paths = [ pkgs.pi-coding-agent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi --run ${lib.escapeShellArg ''
        CLIPROXYAPI_API_KEY="$( ${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.${cfg.cpaApiKeySecret}.path} )" || exit 1
        test -n "$CLIPROXYAPI_API_KEY" || exit 1
        export CLIPROXYAPI_API_KEY
      ''}
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
      package = if cfg.cpaApiKeySecret == null then pkgs.pi-coding-agent else package;
      extraPackages = [ pkgs.nodejs ];
      context = ./AGENTS.md;
      # settings.json stays writable for /settings, /model and pi install.
    };

    sops.secrets = lib.mkIf (cfg.cpaApiKeySecret != null) {
      ${cfg.cpaApiKeySecret} = { };
    };

    home.file = {
      ".pi/agent/pi-cliproxyapi-provider/config.json".text = builtins.toJSON {
        providerName = "cpa";
        baseUrl = "http://172.16.20.91:8317/v1";
        authRequired = true;
        authHeader = true;
      };
      ".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON {
        authorizerChain = [ "classifier" ];
        permission = {
          "*" = "ask";
          path = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "*.env.example" = "allow";
            "~/.ssh/*" = "deny";
            "~/.config/sops/*" = "deny";
            "~/.pi/agent/auth.json" = "deny";
            "~/.codex/auth.json" = "deny";
            "${config.sops.defaultSymlinkPath}/*" = "deny";
          };
          read = "allow";
          grep = "allow";
          find = "allow";
          ls = "allow";
          write = "allow";
          edit = "allow";
          bash = "ask";
          external_directory = "ask";
        };
      };
    };

    # Reapply declared defaults, preserving other runtime settings and packages.
    # Do not manage models.json: existing local providers remain local.
    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.python3}/bin/python3 ${./merge-settings.py} \
        ${lib.escapeShellArg agentDir} ${settings}
    '';
  };
}
