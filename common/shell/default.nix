{ config, ... }:
{
  sops.secrets.gh-cli-token = {};

  programs = {
    nushell = {
      enable = true;
      configFile.source = ./config.nu;
      extraEnv = ''
        if ("${config.sops.secrets.gh-cli-token.path}" | path exists) {
          $env.GH_TOKEN = (open --raw "${config.sops.secrets.gh-cli-token.path}" | str trim)
          $env.GITHUB_TOKEN = $env.GH_TOKEN
        }
      '';
    };

    carapace = {
      enable = true;
      enableNushellIntegration = false;
    };

    starship = {
      enable = true;
      settings.add_newline = true;
    };

    nix-your-shell = {
      enable = true;
      enableNushellIntegration = true;
    };
  };

  services = {
    pueue = {
      enable = true;
    };
  };
}
