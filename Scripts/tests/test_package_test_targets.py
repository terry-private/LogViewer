"""テスト対象を追加した場合と、取得失敗時のCI契約。"""

import json
from pathlib import Path
import subprocess
import sys
import unittest
import tempfile


SCRIPT = Path(__file__).resolve().parents[1] / "package-test-targets.py"


class PackageTestTargetsTests(unittest.TestCase):
    def test_scheme_missing_or_skipped_target_fails(self):
        manifest = json.dumps({"targets": [{"name": "NewTests", "type": "test"}]})
        for name, skipped, expected in [("NewTests", "NO", 0), ("OldTests", "NO", 1), ("NewTests", "YES", 1)]:
            with self.subTest(name=name, skipped=skipped), tempfile.TemporaryDirectory() as directory:
                scheme = Path(directory) / "Tests.xcscheme"
                scheme.write_text(f'<Scheme><TestAction><Testables><TestableReference skipped="{skipped}"><BuildableReference BlueprintIdentifier="{name}"/></TestableReference></Testables></TestAction></Scheme>')
                result = subprocess.run([sys.executable, str(SCRIPT), str(scheme)], input=manifest, text=True, capture_output=True)
                self.assertEqual(result.returncode, expected, result.stderr)
                self.assertEqual(result.stdout, "NewTests\n" if expected == 0 else "")

    def run_script(self, text):
        return subprocess.run([sys.executable, str(SCRIPT)], input=text, text=True, capture_output=True)

    def test_discovers_new_target_without_including_production(self):
        result = self.run_script(json.dumps({"targets": [
            {"name": "Production", "type": "regular"},
            {"name": "ExistingTests", "type": "test"},
            {"name": "NewTests", "type": "test"},
        ]}))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["ExistingTests", "NewTests"])

    def test_invalid_input_fails_without_partial_output(self):
        for text in ["invalid", "{}", '{"targets": []}',
                     '{"targets": [{"type": "test", "name": "Bad Name"}]}',
                     '{"targets": [{"type": "test", "name": "Tests"}, {"type": "test", "name": "Tests"}]}']:
            with self.subTest(text=text):
                result = self.run_script(text)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertTrue(result.stderr)


if __name__ == "__main__":
    unittest.main()
