{ 
  config,
  pkgs,
  ...
}:
{
  programs.opencode = {
    enable = true;
  };

  sops.templates."opencode.json".content = let
    placeholders = config.sops.placeholder;
  in ''{
    "$schema": "https://opencode.ai/config.json",

    "theme": "nord",

    "provider": {
      "ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama",
        "options": {
          "baseURL": "${placeholders.internal-ollama-url}"
        },
        "models": {
          "qwen3-coder-next:q8_0": {
            "name": "qwen3-coder-next:q8_0"
          }
        }
      }
    },

    "mcp": {
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp",
        "headers": {
          "CONTEXT7_API_KEY": "${placeholders.context7-api-key}"
        },
        "enabled": true
      }
    }
  }'';

  home.file.".config/opencode/agents" = {
    source = ./agents;
    recursive = true;
  };

  sops.secrets = {
    internal-ollama-url = {};
    context7-api-key = {};
  };

  systemd.user.services.opencode-write-config = {
    Unit = {
      Description = "write opencode config";

      After = [ "sops-nix.service" ];

      X-SwitchMethod = "restart";
      X-Reload-Triggers = [
        (builtins.hashString "md5" config.sops.templates."opencode.json".content)
      ];
    };

    Service = {
      ExecStart = "${pkgs.writers.writeBash "opencode-write-config" ''
        ${pkgs.coreutils-full}/bin/mkdir -p ~/.config/opencode
        ${pkgs.coreutils-full}/bin/install -m 400 -D ${config.sops.templates."opencode.json".path} ~/.config/opencode/opencode.json 
      ''}";
    };

    Install = {
      WantedBy = [
        "default.target"
      ];
    };
  };
}
