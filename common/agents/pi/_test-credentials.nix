# Evaluate real ugly-rod modules; build only synthetic credential-config fixtures.
# nix build --impure --no-link --expr 'import ./common/agents/pi/_test-credentials.nix { flake = builtins.getFlake ("path:" + toString ./.); }'
{ flake }:
let
  home = flake.homeConfigurations.ugly-rod;
  inherit (home) pkgs;
  inherit (pkgs) lib;
  secretPath = "/tmp/pi-credential-fixture/key ' spaces $(not-a-command)";
  fixture = home.extendModules {
    modules = [{
      programs.pi-coding-agent.cpaApiKeySecret = lib.mkForce "fixture-cpa";
      sops.secrets = lib.genAttrs [ "exa-api-key" "deepseek-api-key" "fixture-cpa" ]
        (_: { path = lib.mkForce secretPath; });
    }];
  };
  optional = home.extendModules {
    modules = [{ programs.pi-coding-agent.cpaApiKeySecret = lib.mkForce null; }];
  };
  template = config: builtins.fromJSON
    (builtins.unsafeDiscardStringContext config.sops.templates."pi-cliproxyapi-provider.json".content);
  cpa = template fixture.config;
  optionalCpa = template optional.config;
  command = "!${pkgs.coreutils}/bin/cat ${lib.escapeShellArg secretPath}";
  # The activation's last argument is its generated, path-only credentials JSON.
  args = lib.splitString " " (lib.trim fixture.config.home.activation.piSettings.data);
  credentials = lib.strings.addContextFrom fixture.config.home.activation.piSettings.data (lib.last args);
in
assert home.config.programs.pi-coding-agent.package == pkgs.pi-coding-agent;
assert builtins.elem pkgs.nodejs home.config.programs.pi-coding-agent.extraPackages;
assert cpa.apiKey == command && cpa.authRequired && cpa.authHeader && !(cpa ? headers);
assert !(optionalCpa ? apiKey) && optionalCpa.authRequired && optionalCpa.authHeader;
assert !(optional.config.sops.secrets ? pi-cpa-api-key);
assert !(lib.hasInfix "auth.json" fixture.config.home.activation.piSettings.data);
assert lib.all (name: fixture.config.sops.secrets.${name}.mode == "0400")
  [ "exa-api-key" "deepseek-api-key" "fixture-cpa" ];
assert fixture.config.sops.templates."pi-cliproxyapi-provider.json".mode == "0400";
pkgs.runCommand "pi-credential-config-check" {
  nativeBuildInputs = [ pkgs.python3 ];
  inherit credentials secretPath;
  cat = "${pkgs.coreutils}/bin/cat";
  cpaCommand = cpa.apiKey;
} ''
  python3 <<'PY'
  import json
  import os
  from pathlib import Path
  import shlex
  import subprocess

  credentials = json.loads(Path(os.environ["credentials"]).read_text())
  path = Path(os.environ["secretPath"])
  path.parent.mkdir(parents=True)
  path.write_text("synthetic-path-quoting-fixture\n")
  for command in [os.environ["cpaCommand"], *credentials.values()]:
      assert command.startswith("!")
      assert shlex.split(command[1:]) == [os.environ["cat"], str(path)]
      assert subprocess.check_output(command[1:], shell=True, text=True).strip() == "synthetic-path-quoting-fixture"
      assert "synthetic-path-quoting-fixture" not in command
  assert set(credentials) == {"deepseekApiKey", "exaApiKey"}
  print("Native package/PATH, optional CPA, SOPS modes and all three shell-quoted path-only commands OK")
  PY
  touch $out
''
