import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "verify_generated", Path(__file__).with_name("verify_generated.py")
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GeneratedSourceGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="flutter_generated_")
        self.root = Path(self.temp.name)
        self.git("init", "-q")
        self.write("lib/model.g.dart", "// committed output\n")
        self.write(".gitignore", "lib/ignored/\n**/.dart_tool/\n")
        self.git("add", ".")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "commit", "-qm", "fixture")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, check=True,
                              capture_output=True)

    def write(self, path, content):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def check(self):
        return MODULE.inspect_sources(self.root, ["lib", "test", "tool"])

    def test_clean_checkout_passes(self):
        self.assertEqual(self.check(), [])

    def test_changed_tracked_output_is_reported(self):
        self.write("lib/model.g.dart", "// changed\n")
        self.assertIn("lib/model.g.dart", self.check())

    def test_staged_output_is_reported(self):
        self.write("lib/model.g.dart", "// changed\n")
        self.git("add", "lib/model.g.dart")
        self.assertIn("lib/model.g.dart", self.check())

    def test_new_untracked_output_with_spaces_is_reported(self):
        self.write("lib/new output.g.dart", "// new\n")
        self.assertIn("lib/new output.g.dart", self.check())

    def test_ignored_generated_source_is_reported(self):
        self.write("lib/ignored/model.g.dart", "// ignored\n")
        self.assertIn("lib/ignored/model.g.dart", self.check())

    def test_tool_dependency_cache_is_excluded(self):
        self.write("tool/check/.dart_tool/hooks/generated.dart", "// cache\n")
        self.assertEqual(self.check(), [])

    def test_lib_directory_named_build_is_still_a_source(self):
        self.write("lib/build/model.g.dart", "// new source\n")
        self.assertIn("lib/build/model.g.dart", self.check())

    def test_lib_directory_named_coverage_is_still_a_source(self):
        self.write("lib/coverage/model.g.dart", "// new source\n")
        self.assertIn("lib/coverage/model.g.dart", self.check())

    def test_tool_package_build_output_is_excluded(self):
        self.write("tool/check/pubspec.yaml", "name: checks\n")
        self.git("add", "tool/check/pubspec.yaml")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "commit", "-qm", "tool package")
        self.write("tool/check/build/intermediate.dart", "// generated cache\n")
        self.assertEqual(self.check(), [])

    def test_outside_source_scope_is_not_reported(self):
        self.write("docs/note.md", "notes\n")
        self.assertEqual(self.check(), [])

    def test_relative_escape_is_rejected(self):
        with self.assertRaises(ValueError):
            MODULE.inspect_sources(self.root, ["../elsewhere"])

    def test_nested_repository_path_is_rejected(self):
        with self.assertRaises(ValueError):
            MODULE.inspect_sources(self.root / "lib", ["."])


if __name__ == "__main__":
    unittest.main()
