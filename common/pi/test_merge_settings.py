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
        defaults = {"defaultProvider": "cpa", "packages": ["npm:pi-vim@0.14.2", "npm:@gotgenes/pi-permission-system@40.2.0"]}
        current = {"theme": "light", "packages": ["npm:pi-vim", "npm:pi-vim@0.1.0", "npm:@gotgenes/pi-permission-system", "npm:other", {"source": "./local", "extensions": []}]}
        merged = module.merge_settings(current, defaults)
        self.assertEqual(merged["packages"], defaults["packages"] + current["packages"][-2:])
        self.assertEqual(merged["theme"], "light")
        self.assertEqual(module.merge_settings(merged, defaults), merged)

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
            classifier = directory / "extensions/pi-permission-classifier/config.json"
            classifier.write_text('{"provider": "cpa", "model": "custom"}')
            subprocess.run(command, check=True)
            self.assertEqual(json.loads(classifier.read_text())["model"], "custom")
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
