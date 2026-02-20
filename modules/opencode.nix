{ 
  config,
  pkgs,
  ...
}:
{
  programs.opencode = {
    enable = true;
  };

  sops.templates."opencode.json".content = ''{
    "$schema": "https://opencode.ai/config.json",

    "theme": "nord",

    "provider": {
      "ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama",
        "options": {
          "baseURL": "${config.sops.placeholder.internal-ollama-url}"
        },
        "models": {
          "qwen3-coder-next:q8_0": {
            "name": "qwen3-coder-next:q8_0"
          }
        }
      }
    }
  }'';

  sops.secrets.internal-ollama-url = {};

  systemd.user.services.opencode-write-config = {
    Service = {
      ExecStart = "${pkgs.writeShellScript "opencode-write-config" ''
        mkdir -p ~/opencode
        cp ${config.sops.templates."opencode.json".path} ~/opencode/opencode.json
      ''}";
    };
  };
}
