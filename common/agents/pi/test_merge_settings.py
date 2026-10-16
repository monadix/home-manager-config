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
        defaults = {"defaultProvider": "cpa", "packages": ["npm:pi-vim@0.14.2", "npm:@fadouse/pi-permission@0.1.2"]}
        current = {"theme": "light", "packages": ["npm:pi-vim", "npm:pi-vim@0.1.0", "npm:@gotgenes/pi-permission-system", "npm:pi-permission-classifier@0.5.2", "npm:other", {"source": "./local", "extensions": []}]}
        merged = module.merge_settings(current, defaults)
        self.assertEqual(merged["packages"], defaults["packages"] + current["packages"][-2:])
        self.assertEqual(merged["theme"], "light")
        self.assertEqual(module.merge_settings(merged, defaults), merged)

    def test_bundle_replaces_old_npm_and_store_sources(self):
        path = "/nix/store/new/lib/pi-extensions/node_modules/"
        defaults = {"packages": [path + "pi-vim", path + "@fadouse/pi-permission"]}
        current = {"packages": [
            "npm:pi-vim@0.14.2",
            {"source": "npm:@gotgenes/pi-permission-system", "skills": []},
            "/nix/store/old/lib/pi-extensions/node_modules/pi-vim",
            {"source": "/nix/store/old/lib/pi-extensions/node_modules/pi-permission-classifier"},
            {"source": "npm:@fadouse/pi-permission@0.1.1"},
            "npm:unrelated",
        ]}
        self.assertEqual(module.merge_settings(current, defaults)["packages"],
                         defaults["packages"] + ["npm:unrelated"])

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
        self.assertEqual(merged["providers"]["openai"], current["providers"]["openai"])
        self.assertNotIn("openai", module.merge_models({})["providers"])
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
