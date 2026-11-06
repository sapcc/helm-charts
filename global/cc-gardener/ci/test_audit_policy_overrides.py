"""Exercise discovery and validation through the real YAML parser and checker."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("audit-policy-overrides.py")
SAFE = 'apiVersion: audit.k8s.io/v1\nkind: "Policy"\nrules:\n- level: Metadata\n'
UNSAFE = SAFE.replace("Metadata", "RequestResponse")


class OverrideChecks(unittest.TestCase):
    def run_check(self, files, expected):
        with tempfile.TemporaryDirectory() as directory:
            for name, contents in files.items():
                file = Path(directory) / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(contents)
            result = subprocess.run([sys.executable, str(SCRIPT), directory], text=True, capture_output=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout

    def test_all_nested_policies_are_checked(self):
        values = {"first": {"gardenPolicy": SAFE}, "second": {"gardenPolicy": UNSAFE}}
        output = self.run_check({"values.yaml": json.dumps(values)}, 1)
        self.assertIn("document-1/second/gardenPolicy", output)
        self.assertIn("Checked 2 audit policy override(s)", output)

    def test_lists_and_yml_files_are_checked(self):
        values = [{"virtualPolicy": SAFE}, {"virtualPolicy": UNSAFE}]
        output = self.run_check({"nested/values.yml": json.dumps(values)}, 1)
        self.assertIn("document-1/1/virtualPolicy", output)

    def test_all_values_documents_are_checked(self):
        documents = json.dumps({"gardenPolicy": SAFE}) + "\n---\n" + json.dumps({"gardenPolicy": UNSAFE})
        output = self.run_check({"values.yaml": documents}, 1)
        self.assertIn("document-2/gardenPolicy", output)

    def test_valid_quoted_kind_and_both_policy_keys(self):
        output = self.run_check({"values.yaml": json.dumps({"gardenPolicy": SAFE, "virtualPolicy": SAFE})}, 0)
        self.assertIn("Checked 2 audit policy override(s)", output)

    def test_malformed_values_fail_without_disclosing_contents(self):
        output = self.run_check({"values.yaml": "gardenPolicy: [SENSITIVE_SENTINEL\n"}, 1)
        self.assertNotIn("SENSITIVE_SENTINEL", output)

    def test_invalid_policy_values_fail(self):
        for value in (None, "", 42, {}, "kind: [", "kind: ConfigMap", SAFE.replace("rules:", "other:"),
                      SAFE.replace("- level: Metadata", "[]"), SAFE + "---\n" + SAFE):
            with self.subTest(value=value):
                output = self.run_check({"values.yaml": json.dumps({"gardenPolicy": value})}, 1)
                self.assertIn("invalid audit Policy", output)

    def test_invalid_rule_types_fail(self):
        for invalid_rule in ("- null", "- level: invalid", "- level: Metadata\n  resources: wrong"):
            with self.subTest(rule=invalid_rule):
                self.run_check({"values.yaml": json.dumps({"virtualPolicy": SAFE.replace("- level: Metadata", invalid_rule)})}, 1)

    def test_comments_and_unrelated_values_do_not_create_overrides(self):
        output = self.run_check({"values.yaml": "# gardenPolicy uses defaults\nother: true\n"}, 0)
        self.assertIn("Checked 0 audit policy override(s)", output)

    def test_missing_directory_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run([sys.executable, str(SCRIPT), str(Path(directory) / "missing")], capture_output=True)
        self.assertEqual(result.returncode, 1)


if __name__ == "__main__":
    unittest.main()
