import importlib.util
import json
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("merge-settings.py")
spec = importlib.util.spec_from_file_location("merge_settings", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SettingsTests(unittest.TestCase):
    def test_package_pins_preserve_unrelated_entries(self):
        defaults = {"defaultProvider": "cpa", "packages": ["npm:pi-vim@0.14.2"]}
        current = {"theme": "light", "packages": [
            "npm:pi-vim", "npm:pi-vim@0.1.0",
            "npm:@gotgenes/pi-permission-system@40.2.2",
            "npm:@erichll/pi-auto-review@0.26.0",
            "npm:@mzwing/pi-permission-auto-review@0.9.1",
            {"source": "npm:@fadouse/pi-permission@0.1.2", "extensions": []},
            "npm:pi-permission-classifier@0.5.2", "npm:pi-scope-sandbox",
            "npm:other", {"source": "./local", "extensions": []},
        ]}
        merged = module.merge_settings(current, defaults)
        self.assertEqual(merged["packages"], defaults["packages"] + current["packages"][-2:])
        self.assertEqual(merged["theme"], "light")
        self.assertEqual(module.merge_settings(merged, defaults), merged)

    def test_retired_permission_packages_are_removed_from_npm_store_and_objects(self):
        path = "/nix/store/new/lib/pi-extensions/node_modules/"
        defaults = {"packages": [path + "pi-vim"]}
        current = {"packages": [
            "npm:pi-vim@0.14.2",
            {"source": "npm:@gotgenes/pi-permission-system@40.2.2", "skills": []},
            "/nix/store/old/lib/pi-extensions/node_modules/pi-vim",
            {"source": "/nix/store/old/lib/pi-extensions/node_modules/pi-permission-classifier"},
            {"source": "npm:@fadouse/pi-permission@0.1.1"},
            "/nix/store/old/lib/pi-extensions/node_modules/@fadouse/pi-permission",
            {"source": "npm:@mzwing/pi-permission-auto-review@0.9.1"},
            "/nix/store/old/lib/pi-extensions/node_modules/@mzwing/pi-permission-auto-review",
            {"source": "npm:@erichll/pi-auto-review@0.25.0", "extensions": []},
            "/nix/store/old/lib/pi-extensions/node_modules/@erichll/pi-auto-review",
            "/nix/store/old/lib/pi-extensions/node_modules/@gotgenes/pi-permission-system",
            "/nix/store/old/lib/pi-extensions/node_modules/pi-scope-sandbox",
            "npm:unrelated", {"source": "./local", "extensions": []},
        ]}
        merged = module.merge_settings(current, defaults)
        self.assertEqual(merged["packages"], defaults["packages"] + ["npm:unrelated", {"source": "./local", "extensions": []}])
        self.assertEqual(module.merge_settings(merged, defaults), merged)

    def test_model_override_preserves_local_configuration(self):
        current = {"providers": {
            "local": {"models": [{"id": "existing"}]},
            "cpa": {"modelOverrides": {
                "other": {"contextWindow": 128000},
                "gpt-6.1-sol": {"reasoning": True, "contextWindow": 128000},
            }},
        }}
        merged = module.merge_models(current)
        self.assertEqual(merged["providers"]["local"], current["providers"]["local"])
        overrides = merged["providers"]["cpa"]["modelOverrides"]
        self.assertEqual(overrides["gpt-6.1-sol"], {"reasoning": True, "contextWindow": 500000})
        self.assertEqual(overrides["other"], {"contextWindow": 128000})
        for model in ["gpt-6-sol", "gpt-5.6-sol", "gpt-5.5"]:
            self.assertEqual(overrides[model]["contextWindow"], 272000)
        self.assertEqual(len(overrides), 5)
        self.assertEqual(module.merge_models(merged), merged)
        self.assertEqual(current["providers"]["cpa"]["modelOverrides"]["gpt-6.1-sol"]["contextWindow"], 128000)

    def test_model_merge_preserves_existing_reviewers(self):
        current = {"providers": {"openai": {"headers": {"custom": "value"}, "models": [
            {"id": "other"}, {"id": "codex-auto-review", "contextWindow": 64000},
        ]}}}
        merged = module.merge_models(current)
        self.assertEqual(merged["providers"]["openai"]["headers"], current["providers"]["openai"]["headers"])
        self.assertEqual(merged["providers"]["openai"]["models"][:-1], current["providers"]["openai"]["models"])
        self.assertEqual(merged["providers"]["openai"]["models"][-1]["id"], "gpt-6.1-terra")
        self.assertEqual(module.merge_models({})["providers"]["openai"]["modelOverrides"], {
            "gpt-6.1-sol": {"contextWindow": 500000},
        })
        self.assertNotIn("modelOverrides", current["providers"]["openai"])
        self.assertEqual(module.merge_models(merged), merged)

    def test_openai_override_preserves_existing_metadata(self):
        current = {"providers": {"openai": {"modelOverrides": {
            "gpt-6.1-sol": {"reasoning": True, "contextWindow": 272000},
            "other": {"contextWindow": 128000},
        }}}}
        merged = module.merge_models(current)
        self.assertEqual(merged["providers"]["openai"]["modelOverrides"], {
            "gpt-6.1-sol": {"reasoning": True, "contextWindow": 500000},
            "other": {"contextWindow": 128000},
        })
        self.assertEqual(current["providers"]["openai"]["modelOverrides"]["gpt-6.1-sol"]["contextWindow"], 272000)
        self.assertEqual(module.merge_models(merged), merged)

    def test_terra_registration_uses_each_providers_api(self):
        merged = module.merge_models({})
        for provider, api in (
            ("openai", "openai-responses"),
            ("openai-codex", "openai-codex-responses"),
        ):
            with self.subTest(provider=provider):
                model, = merged["providers"][provider]["models"]
                self.assertEqual(model["id"], "gpt-6.1-terra")
                self.assertEqual(model["api"], api)
                self.assertTrue(model["reasoning"])
                self.assertEqual(model["input"], ["text", "image"])
                self.assertEqual(model["contextWindow"], 272000)
                self.assertEqual(model["maxTokens"], 128000)
        self.assertEqual(module.merge_models(merged), merged)

    def test_terra_registration_preserves_existing_entries_and_provider_settings(self):
        for provider in ("openai", "openai-codex"):
            with self.subTest(provider=provider):
                current = {"providers": {provider: {
                    "headers": {"custom": "value"},
                    "models": [
                        {"id": "other"},
                        {"id": "gpt-6.1-terra", "contextWindow": 128000,
                         "samplingParams": {"temperature": 0.5}},
                    ],
                }}}
                original = json.loads(json.dumps(current))
                merged = module.merge_models(current)
                settings = merged["providers"][provider]
                self.assertEqual(settings["headers"], current["providers"][provider]["headers"])
                self.assertEqual(len(settings["models"]), 2)
                self.assertEqual(settings["models"][0], {"id": "other"})
                self.assertEqual(settings["models"][1]["contextWindow"], 128000)
                self.assertEqual(settings["models"][1]["samplingParams"], {"temperature": 0.5})
                self.assertTrue(settings["models"][1]["reasoning"])
                self.assertEqual(current, original)
                self.assertEqual(module.merge_models(merged), merged)

    def test_codex_61_context_overrides_preserve_other_metadata(self):
        current = {"providers": {"openai-codex": {"modelOverrides": {
            "gpt-6.1-sol": {"reasoning": True, "contextWindow": 500000},
            "gpt-6.1-terra": {"name": "Local Terra", "contextWindow": 272000},
            "other": {"contextWindow": 128000},
        }}}}
        original = json.loads(json.dumps(current))
        merged = module.merge_models(current)
        self.assertEqual(merged["providers"]["openai-codex"]["modelOverrides"], {
            "gpt-6.1-sol": {"reasoning": True, "contextWindow": 872000},
            "gpt-6.1-terra": {"name": "Local Terra", "contextWindow": 872000},
            "other": {"contextWindow": 128000},
        })
        for provider in ("openai", "cpa"):
            self.assertEqual(merged["providers"][provider]["modelOverrides"]["gpt-6.1-sol"]["contextWindow"], 500000)
        self.assertEqual(current, original)
        self.assertEqual(module.merge_models(merged), merged)

    def test_activation_backup_mutability_and_invalid_input(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "agent"
            directory.mkdir()
            path = directory / "settings.json"
            original = '{"custom": true, "packages": []}'
            path.write_text(original)
            defaults = root / "defaults.json"
            defaults.write_text('{"packages": ["npm:pi-vim@0.14.2"]}')
            command = [sys.executable, str(SCRIPT), str(directory), str(defaults)]
            subprocess.run(command, check=True)
            backup = directory / "settings.json.pre-hm"
            self.assertEqual(backup.read_text(), original)
            self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
            subprocess.run(command, check=True)
            self.assertFalse((directory / "extensions/pi-permission-classifier/config.json").exists())
            self.assertEqual(backup.read_text(), original)
            path.write_text("invalid")
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(path.read_text(), "invalid")
            path.unlink()
            path.symlink_to(defaults)
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertTrue(path.is_symlink())


if __name__ == "__main__":
    unittest.main()
