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
    Unit = {
      X-SwitchMethod = "restart";
      Description = "write opencode config";
    };
    Service = {
      ExecStart = "${pkgs.writers.writeBash "opencode-write-config" ''
        ${pkgs.coreutils-full}/bin/rm -f ~/.config/opencode/opencode.json
        ${pkgs.coreutils-full}/bin/mkdir -p ~/.config/opencode 
        ${pkgs.coreutils-full}/bin/cp ${config.sops.templates."opencode.json".path} ~/.config/opencode/opencode.json 
      ''}";
    };
  };
}
